# frozen_string_literal: true

class DoiResourceParameters
  def initialize(resource, actor:)
    resource_hash =
      if resource.respond_to?(:to_unsafe_h)
        resource.to_unsafe_h
      else
        resource.to_h
      end
    @resource = ActionController::Parameters.new(resource_hash)
    @actor = actor
  end

  def permitted_resource
    @permitted_resource ||=
      begin
        normalize_alternate_identifiers!

        resource.permit(
          :type,
          :id,
          attributes: ParamsSanitizer::ATTRIBUTES_MAP,
          relationships: ParamsSanitizer::RELATIONSHIPS_MAP,
        ).to_h
      end
  end

  def sanitized_attributes
    attributes = permitted_resource.fetch("attributes", {}).with_indifferent_access
    ParamsSanitizer.new(attributes.merge(client_id: client_id)).cleanse
  end

  def client_id
    permitted_resource.dig("relationships", "client", "data", "id") ||
      actor.try(:client_id)
  end

  def id
    permitted_resource["id"]
  end

  def mode
    permitted_resource.dig("attributes", "mode")
  end

  private
    attr_reader :resource, :actor

    def normalize_alternate_identifiers!
      attributes = resource[:attributes]
      return if attributes.blank? ||
        attributes.key?(:identifiers) ||
        !attributes.key?(:alternateIdentifiers)

      alternate_identifiers = attributes[:alternateIdentifiers]
      attributes[:identifiers] =
        if alternate_identifiers.nil?
          nil
        else
          Array.wrap(alternate_identifiers).map do |identifier|
            if identifier.respond_to?(:fetch)
              {
                identifier: identifier.fetch(:alternateIdentifier),
                identifierType: identifier.fetch(:alternateIdentifierType),
              }
            else
              identifier
            end
          end
        end
    end
end
