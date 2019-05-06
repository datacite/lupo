require 'types/base_object'
require 'types/base_interface'

require 'types/doi_item_type'
require 'types/provider_type'
require 'types/client_type'
require 'types/prefix_type'
require 'types/funder_type'
require 'types/researcher_type'
require 'types/organization_type'
require 'types/dataset_type'
require 'types/publication_type'
require 'types/software_type'
require 'types/other_type'
require 'types/workflow_type'
require 'types/sound_type'
require 'types/service_type'
require 'types/physical_object_type'
require 'types/model_type'
require 'types/interactive_resource_type'
require 'types/image_type'
require 'types/event_type'
require 'types/data_paper_type'
require 'types/collection_type'
require 'types/audiovisual_type'

module Types
  class MutationType < BaseObject
    field :providers, [ProviderType], null: false

    def providers
      Provider.query(nil)
    end

    field :clients, [ClientType], null: false

    def clients
      Client.query(nil)
    end

    field :prefixes, [PrefixType], null: false

    def prefixes
      Prefix.all
    end
  end
end
