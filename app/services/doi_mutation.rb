# frozen_string_literal: true

class DoiMutation
  include Helpable

  Result = Struct.new(:doi, :status, :created, keyword_init: true) do
    def success?
      doi.errors.empty? && status.present?
    end
  end

  def initialize(operation:, attributes:, actor:, id: nil, mode: nil, authorizer: nil)
    @operation = operation.to_s
    @attributes = attributes
    @actor = actor
    @id = id
    @mode = mode
    @authorizer = authorizer
  end

  def call
    operation == "create" ? create : update
  end

  private
    attr_reader :operation, :attributes, :actor, :id, :mode, :authorizer

    def create
      doi = DataciteDoi.new(attributes)
      doi.current_user = actor
      authorize!(:new, doi)

      if doi.save
        Result.new(doi: doi, status: :created, created: true)
      else
        Result.new(doi: doi)
      end
    end

    def update
      doi = DataciteDoi.where(doi: id).first
      exists = doi.present?
      should_validate = true

      if exists
        doi.current_user = actor

        if mode == "transfer"
          authorize!(:transfer, doi)
          doi.assign_attributes(attributes.slice(:client_id))
          should_validate = false
        else
          authorize!(:update, doi)
          assign_update_attributes(doi)
        end
      else
        doi_id = validate_doi(id)
        fail ActiveRecord::RecordNotFound if doi_id.blank?

        doi = DataciteDoi.new(attributes.merge(doi: doi_id))
        doi.current_user = actor
        authorize!(:new, doi)
      end

      if doi.save(validate: should_validate)
        Result.new(
          doi: doi,
          status: exists ? :ok : :created,
          created: !exists,
        )
      else
        Result.new(doi: doi)
      end
    end

    def assign_update_attributes(doi)
      update_attributes = attributes.except(:doi, :client_id)

      if attributes[:schema_version].blank?
        update_attributes =
          update_attributes.merge(
            schema_version: doi[:schema_version] || LAST_SCHEMA_VERSION,
          )
      end

      doi.assign_attributes(update_attributes)
    end

    def authorize!(action, resource)
      authorizer&.call(action, resource)
    end
end
