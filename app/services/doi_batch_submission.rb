# frozen_string_literal: true

require "set"

class DoiBatchSubmission
  include Helpable

  MAX_ITEMS = 1_000

  def initialize(operation:, resources:, actor:, authorizer:)
    @operation = operation.to_s
    @resources = Array.wrap(resources)
    @actor = actor
    @authorizer = authorizer
    @generated_dois = Set.new
  end

  def call
    validate_collection!

    batch =
      DoiBatch.transaction do
        batch = DoiBatch.create!(
          operation: operation,
          submitted_by: actor.uid,
          role_id: actor.role_id,
          client_id: actor.client_id,
          provider_id: actor.provider_id,
          total_count: resources.length,
        )

        resources.each_with_index do |resource, position|
          batch.items.create!(build_item_attributes(resource, position))
        end

        batch
      end

    DoiBatchProcessJob.perform_later(batch.id)
    batch
  end

  private
    attr_reader :operation, :resources, :actor, :authorizer, :generated_dois

    def validate_collection!
      unless operation.in?(DoiBatch::OPERATIONS)
        raise ActionController::BadRequest, "Invalid DOI batch operation"
      end
      if resources.empty?
        raise ActionController::BadRequest, "A DOI batch must contain at least one item"
      end
      if resources.length > MAX_ITEMS
        raise ActionController::BadRequest,
              "A DOI batch cannot contain more than #{MAX_ITEMS} items"
      end
    end

    def build_item_attributes(resource, position)
      resource_params = DoiResourceParameters.new(resource, actor: actor)
      payload = resource_params.permitted_resource.deep_dup
      validate_resource!(payload, resource_params, position)

      doi, generated_doi =
        if operation == "create"
          prepare_create!(payload, resource_params)
        else
          prepare_update!(payload, resource_params)
        end

      {
        position: position,
        doi: doi,
        generated_doi: generated_doi,
        payload: payload,
      }
    end

    def validate_resource!(payload, resource_params, position)
      if payload["type"].present? && payload["type"] != "dois"
        raise ActionController::BadRequest,
              "Batch item #{position} must have type dois"
      end
      unless payload["attributes"].is_a?(Hash)
        raise ActionController::BadRequest,
              "Batch item #{position} must include attributes"
      end
      if resource_params.mode == "transfer"
        raise ActionController::BadRequest,
              "Transfer mode is not supported in DOI batches"
      end
    end

    def prepare_create!(payload, resource_params)
      attributes = payload.fetch("attributes")
      doi = attributes["doi"] || doi_from_xml(attributes["xml"])
      generated_doi = false

      if doi.blank? && attributes["prefix"].present?
        doi = generate_unique_doi(attributes["prefix"])
        generated_doi = true
      end

      doi = validate_doi(doi)
      if doi.blank?
        raise ActionController::BadRequest,
              "Batch create items require a valid doi, XML DOI, or prefix"
      end

      attributes["doi"] = doi
      candidate = DataciteDoi.new(doi: doi, client_id: resource_params.client_id)
      authorizer.call(:new, candidate)
      [doi, generated_doi]
    end

    def prepare_update!(payload, resource_params)
      id = resource_params.id
      doi_id = validate_doi(id)
      if doi_id.blank?
        raise ActionController::BadRequest,
              "Batch update items require a valid data.id"
      end

      doi = DataciteDoi.where(doi: id).first
      if doi.present?
        authorizer.call(:update, doi)
      else
        candidate =
          DataciteDoi.new(doi: doi_id, client_id: resource_params.client_id)
        authorizer.call(:new, candidate)
      end

      [doi_id, false]
    end

    def generate_unique_doi(prefix)
      10.times do
        doi = generate_random_dois(prefix).first
        next if generated_dois.include?(doi) || DataciteDoi.exists?(doi: doi)

        generated_dois << doi
        return doi
      end

      raise ActiveRecord::RecordNotUnique,
            "Unable to allocate a unique DOI for this batch"
    end

    def doi_from_xml(encoded_xml)
      return if encoded_xml.blank?

      xml = Nokogiri::XML(Base64.decode64(encoded_xml))
      xml.at_xpath(
        "//*[local-name()='identifier' and translate(@identifierType, 'doi', 'DOI')='DOI']",
      )&.text
    rescue Nokogiri::XML::SyntaxError, ArgumentError
      nil
    end
end
