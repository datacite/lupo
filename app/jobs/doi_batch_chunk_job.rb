# frozen_string_literal: true

require "set"

class DoiBatchChunkJob < ApplicationJob
  include Helpable

  queue_as :lupo_doi_batch

  retry_on StandardError, wait: :polynomially_longer, attempts: 3 do |job, error|
    job.send(:fail_unfinished_items!, error)
  end

  INPUT_ERRORS = [
    ActionController::BadRequest,
    ActionController::ParameterMissing,
    ActionController::UnpermittedParameters,
    ActiveRecord::RecordInvalid,
    ActiveRecord::RecordNotFound,
    CanCan::AccessDenied,
    JSON::ParserError,
    Nokogiri::XML::SyntaxError,
  ].freeze

  def perform(item_ids)
    item_ids.each { |item_id| process_item(item_id) }
  end

  private
    def process_item(item_id)
      item = DoiBatchItem.find_by(id: item_id)
      return if item.blank? || item.terminal?

      DoiBatchItem.transaction do
        item.lock!
        return if item.terminal?

        actor = DoiBatchActor.new(item.doi_batch)
        ability = Ability.new(actor)
        item.assign_attributes(
          status: "processing",
          started_at: item.started_at || Time.zone.now,
        )

        Audited.audit_class.as_user(actor.uid) do
          result = mutate_with_generated_doi_retry(item, actor, ability)
          if result.success?
            complete_item!(
              item,
              status: "succeeded",
              doi: result.doi.uid,
              response_status: Rack::Utils.status_code(result.status),
              result_errors: nil,
            )
          else
            complete_item!(
              item,
              status: "failed",
              doi: result.doi.uid || item.doi,
              response_status: 422,
              result_errors: serialize_model_errors(result.doi),
            )
          end
        end
      end
    rescue *INPUT_ERRORS => error
      fail_item!(item_id, error)
    rescue StandardError
      item = DoiBatchItem.find_by(id: item_id)
      return if item&.terminal?

      raise
    end

    def mutate_with_generated_doi_retry(item, actor, ability)
      attempts = 0

      loop do
        resource_params =
          DoiResourceParameters.new(item.payload, actor: actor)
        result =
          DoiMutation.new(
            operation: item.doi_batch.operation,
            id: resource_params.id,
            attributes: resource_params.sanitized_attributes,
            mode: resource_params.mode,
            actor: actor,
            authorizer: ->(action, resource) {
              ability.authorize!(action, resource)
            },
          ).call

        return result unless generated_doi_collision?(item, result)

        attempts += 1
        return result if attempts >= 3

        replace_generated_doi!(item)
      end
    end

    def generated_doi_collision?(item, result)
      item.generated_doi? &&
        !result.success? &&
        result.doi.errors.where(:doi).any? { |error| error.message.include?("already been taken") }
    end

    def replace_generated_doi!(item)
      payload = item.payload.deep_dup
      prefix = payload.dig("attributes", "prefix")

      10.times do
        doi = generate_random_dois(prefix).first
        next if DataciteDoi.exists?(doi: doi) ||
          item.doi_batch.items.where.not(id: item.id).exists?(doi: doi)

        payload["attributes"]["doi"] = doi
        item.assign_attributes(doi: doi, payload: payload)
        return
      end

      raise ActiveRecord::RecordNotUnique,
            "Unable to allocate a unique DOI for this batch item"
    end

    def complete_item!(item, attributes)
      successful = attributes.fetch(:status) == "succeeded"
      item.update!(
        attributes.merge(completed_at: Time.zone.now),
      )
      item.doi_batch.record_item_completion!(successful: successful)
    end

    def fail_item!(item_id, error)
      DoiBatchItem.transaction do
        item = DoiBatchItem.lock.find(item_id)
        return if item.terminal?

        complete_item!(
          item,
          status: "failed",
          response_status: 422,
          result_errors: [
            {
              source: "base",
              title: error.message,
              uid: item.doi,
            }.compact,
          ],
        )
      end
    end

    def fail_unfinished_items!(error)
      arguments.first.each do |item_id|
        fail_item!(item_id, error)
      rescue ActiveRecord::RecordNotFound
        next
      end
    end

    def serialize_model_errors(doi)
      seen = Set.new
      doi.errors.each_with_object([]) do |error, errors|
        next if seen.include?(error.attribute)

        seen << error.attribute
        errors << {
          source: error.attribute,
          title: error.message.sub(/^./, &:upcase),
          uid: doi.uid,
        }.compact
      end
    end
end
