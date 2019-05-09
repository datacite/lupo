module Types
  class QueryType < Types::BaseObject
    field :providers, [::Types::ProviderType], null: false do
      argument :query, String, required: false
      argument :first, Int, required: false, default_value: 25
    end

    def providers(query: nil, first: nil)
      Provider.query(query, page: { number: 1, size: first }).records
    end

    field :provider, ::Types::ProviderType, null: false do
      argument :id, ID, required: true
    end

    def provider(id:)
      Provider.unscoped.where("allocator.role_name IN ('ROLE_ALLOCATOR', 'ROLE_ADMIN')").where(deleted_at: nil).where(symbol: id).first
    end

    field :clients, [::Types::ClientType], null: false do
      argument :query, String, required: false
      argument :first, Int, required: false, default_value: 25
    end

    def clients(query: nil, first: nil)
      Client.query(query, page: { number: 1, size: first }).records
    end

    field :client, ::Types::ClientType, null: false do
      argument :id, ID, required: true
    end

    def client(id:)
      Client.where(symbol: id).where(deleted_at: nil).first
    end

    field :prefixes, [::Types::PrefixType], null: false do
      argument :query, String, required: false
      argument :first, Int, required: false, default_value: 25
    end

    def prefixes(query: nil, first: nil)
      if query.present?
        collection = Prefix.query(query)
      else
        collection = Prefix.all
      end

      collection.page(1).per(first)
    end

    field :prefix, ::Types::PrefixType, null: false do
      argument :id, ID, required: true
    end

    def prefix(id:)
      Prefix.where(prefix: id).first
    end

    field :funders, [::Types::FunderType], null: false do
      argument :query, String, required: false
      argument :first, Int, required: false, default_value: 25
    end

    def funders(query: nil, first: nil)
      Funder.query(query, limit: first)
    end

    field :funder, ::Types::FunderType, null: false do
      argument :id, ID, required: true
    end

    def funder(id:)
      Funder.find_by_id(id).first
    end

    field :researcher, ::Types::ResearcherType, null: false do
      argument :id, ID, required: true
    end

    def researcher(id:)
      Researcher.find_by_id(id).first
    end

    field :organizations, [::Types::OrganizationType], null: false do
      argument :query, String, required: false
      argument :first, Int, required: false, default_value: 25
    end

    def organizations(query: nil, first: nil)
      Organization.query(query, limit: first)
    end

    field :organization, ::Types::OrganizationType, null: false do
      argument :id, ID, required: true
    end

    def organization(id:)
      Organization.find_by_id(id).first
    end

    field :datasets, [::Types::DatasetType], null: false do
      argument :query, String, required: false
      argument :first, Int, required: false, default_value: 25
    end

    def datasets(query: nil, first: nil)
      Doi.query(query, resource_type_id: "Dataset", page: { number: 1, size: first })
    end

    field :dataset, ::Types::DatasetType, null: false do
      argument :id, ID, required: true
    end

    def dataset(id:)
      doi = doi_from_url(id)
      Doi.find_by_id(doi).first
    end

    field :publications, [::Types::PublicationType], null: false do
      argument :query, String, required: false
      argument :first, Int, required: false, default_value: 25
    end

    def publications(query: nil, first: nil)
      Doi.query(query, resource_type_id: "Text", page: { number: 1, size: first })
    end

    field :publication, ::Types::PublicationType, null: false do
      argument :id, ID, required: true
    end

    def publication(id:)
      doi = doi_from_url(id)
      Doi.find_by_id(doi).first
    end

    field :audiovisuals, [::Types::AudiovisualType], null: false do
      argument :query, String, required: false
      argument :first, Int, required: false, default_value: 25
    end

    def audiovisuals(query: nil, first: nil)
      Doi.query(query, resource_type_id: "Audiovisual", page: { number: 1, size: first })
    end

    field :audiovisual, ::Types::AudiovisualType, null: false do
      argument :id, ID, required: true
    end

    def audiovisual(id:)
      doi = doi_from_url(id)
      Doi.find_by_id(doi).first
    end

    field :collections, [::Types::CollectionType], null: false do
      argument :query, String, required: false
      argument :first, Int, required: false, default_value: 25
    end

    def collections(query: nil, first: nil)
      Doi.query(query, resource_type_id: "Collection", page: { number: 1, size: first })
    end

    field :collection, ::Types::CollectionType, null: false do
      argument :id, ID, required: true
    end

    def collection(id:)
      doi = doi_from_url(id)
      Doi.find_by_id(doi).first
    end

    field :data_papers, [::Types::DataPaperType], null: false do
      argument :query, String, required: false
      argument :first, Int, required: false, default_value: 25
    end

    def data_papers(query: nil, first: nil)
      Doi.query(query, resource_type_id: "DataPaper", page: { number: 1, size: first })
    end

    field :data_paper, ::Types::DataPaperType, null: false do
      argument :id, ID, required: true
    end

    def data_paper(id:)
      doi = doi_from_url(id)
      Doi.find_by_id(doi).first
    end

    field :events, [::Types::EventType], null: false do
      argument :query, String, required: false
      argument :first, Int, required: false, default_value: 25
    end

    def events(query: nil, first: nil)
      Doi.query(query, resource_type_id: "Event", page: { number: 1, size: first })
    end

    field :event, ::Types::EventType, null: false do
      argument :id, ID, required: true
    end

    def event(id:)
      doi = doi_from_url(id)
      Doi.find_by_id(doi).first
    end

    field :images, [::Types::ImageType], null: false do
      argument :query, String, required: false
      argument :first, Int, required: false, default_value: 25
    end

    def images(query: nil, first: nil)
      Doi.query(query, resource_type_id: "Image", page: { number: 1, size: first })
    end

    field :image, ::Types::ImageType, null: false do
      argument :id, ID, required: true
    end

    def image(id:)
      doi = doi_from_url(id)
      Doi.find_by_id(doi).first
    end

    field :interactive_resources, [::Types::InteractiveResourceType], null: false do
      argument :query, String, required: false
      argument :first, Int, required: false, default_value: 25
    end

    def interactive_resources(query: nil, first: nil)
      Doi.query(query, resource_type_id: "InteractiveResource", page: { number: 1, size: first })
    end

    field :interactive_resource, ::Types::InteractiveResourceType, null: false do
      argument :id, ID, required: true
    end

    def interactive_resource(id:)
      doi = doi_from_url(id)
      Doi.find_by_id(doi).first
    end

    field :models, [::Types::ModelType], null: false do
      argument :query, String, required: false
      argument :first, Int, required: false, default_value: 25
    end

    def models(query: nil, first: nil)
      Doi.query(query, resource_type_id: "Model", page: { number: 1, size: first })
    end

    field :model, ::Types::ModelType, null: false do
      argument :id, ID, required: true
    end

    def model(id:)
      doi = doi_from_url(id)
      Doi.find_by_id(doi).first
    end

    field :physical_objects, [::Types::PhysicalObjectType], null: false do
      argument :query, String, required: false
      argument :first, Int, required: false, default_value: 25
    end

    def physical_objects(query: nil, first: nil)
      Doi.query(query, resource_type_id: "PhysicalObject", page: { number: 1, size: first })
    end

    field :physical_object, ::Types::PhysicalObjectType, null: false do
      argument :id, ID, required: true
    end

    def physical_object(id:)
      doi = doi_from_url(id)
      Doi.find_by_id(doi).first
    end

    field :services, [::Types::ServiceType], null: false do
      argument :query, String, required: false
      argument :first, Int, required: false, default_value: 25
    end

    def services(query: nil, first: nil)
      Doi.query(query, resource_type_id: "Service", page: { number: 1, size: first })
    end

    field :service, ::Types::ServiceType, null: false do
      argument :id, ID, required: true
    end

    def service(id:)
      doi = doi_from_url(id)
      Doi.find_by_id(doi).first
    end

    field :softwares, [::Types::SoftwareType], null: false do
      argument :query, String, required: false
      argument :first, Int, required: false, default_value: 25
    end

    def softwares(query: nil, first: nil)
      Doi.query(query, resource_type_id: "Software", page: { number: 1, size: first })
    end

    field :software, ::Types::SoftwareType, null: false do
      argument :id, ID, required: true
    end

    def software(id:)
      doi = doi_from_url(id)
      Doi.find_by_id(doi).first
    end

    field :sounds, [::Types::SoundType], null: false do
      argument :query, String, required: false
      argument :first, Int, required: false, default_value: 25
    end

    def sounds(query: nil, first: nil)
      Doi.query(query, resource_type_id: "Sound", page: { number: 1, size: first })
    end

    field :sound, ::Types::SoundType, null: false do
      argument :id, ID, required: true
    end

    def sound(id:)
      doi = doi_from_url(id)
      Doi.find_by_id(doi).first
    end

    field :workflows, [::Types::WorkflowType], null: false do
      argument :query, String, required: false
      argument :first, Int, required: false, default_value: 25
    end

    def workflows(query: nil, first: nil)
      Doi.query(query, resource_type_id: "Workflow", page: { number: 1, size: first })
    end

    field :workflow, ::Types::WorkflowType, null: false do
      argument :id, ID, required: true
    end

    def workflow(id:)
      doi = doi_from_url(id)
      Doi.find_by_id(doi).first
    end

    field :others, [::Types::OtherType], null: false do
      argument :query, String, required: false
      argument :first, Int, required: false, default_value: 25
    end

    def others(query: nil, first: nil)
      Doi.query(query, resource_type_id: "Other", page: { number: 1, size: first })
    end

    field :other, ::Types::OtherType, null: false do
      argument :id, ID, required: true
    end

    def other(id:)
      doi = doi_from_url(id)
      Doi.find_by_id(doi).first
    end

    def doi_from_url(url)
      if /\A(?:(http|https):\/\/(dx\.)?(doi.org|handle.test.datacite.org)\/)?(doi:)?(10\.\d{4,5}\/.+)\z/.match(url)
        uri = Addressable::URI.parse(url)
        uri.path.gsub(/^\//, '').downcase
      end
    end
  end
end
