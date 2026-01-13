# frozen_string_literal: true

Rails.application.routes.draw do
  post "/client-api/graphql", to: "graphql#execute"
  get "/client-api/graphql", to: "index#method_not_allowed"

  # global options responder -> makes sure OPTION request for CORS endpoints work
  match "*path",
        via: %i[options],
        to: ->(_) { [204, { "Content-Type" => "text/plain" }] }

  # authentication
  post "token", to: "sessions#create_token"

  # authentication via openid connect in load balancer
  post "oidc-token", to: "sessions#create_oidc_token"

  # send reset link
  post "reset", to: "sessions#reset"

  # content negotiation via index path
  get "/application/vnd.datacite.datacite+xml/:id",
      to: "index#show",
      constraints: { id: /.+/ },
      defaults: { format: :datacite }
  get "/application/vnd.datacite.datacite+json/:id",
      to: "index#show",
      constraints: { id: /.+/ },
      defaults: { format: :datacite_json }
  get "/application/vnd.crosscite.crosscite+json/:id",
      to: "index#show",
      constraints: { id: /.+/ },
      defaults: { format: :crosscite }
  get "/application/vnd.schemaorg.ld+json/:id",
      to: "index#show",
      constraints: { id: /.+/ },
      defaults: { format: :schema_org }
  get "/application/ld+json/:id",
      to: "index#show",
      constraints: { id: /.+/ },
      defaults: { format: :schema_org }
  get "/application/vnd.codemeta.ld+json/:id",
      to: "index#show",
      constraints: { id: /.+/ },
      defaults: { format: :codemeta }
  get "/application/vnd.citationstyles.csl+json/:id",
      to: "index#show",
      constraints: { id: /.+/ },
      defaults: { format: :citeproc }
  get "/application/vnd.jats+xml/:id",
      to: "index#show", constraints: { id: /.+/ }, defaults: { format: :jats }
  get "/application/x-bibtex/:id",
      to: "index#show", constraints: { id: /.+/ }, defaults: { format: :bibtex }
  get "/application/x-research-info-systems/:id",
      to: "index#show", constraints: { id: /.+/ }, defaults: { format: :ris }
  get "/text/csv/:id",
      to: "index#show", constraints: { id: /.+/ }, defaults: { format: :csv }
  get "/text/x-bibliography/:id",
      to: "index#show",
      constraints: { id: /.+/ },
      defaults: { format: :citation }

  # content negotiation
  get "/dois/application/vnd.datacite.datacite+xml/:id",
      to: "datacite_dois#show",
      constraints: { id: /.+/ },
      defaults: { format: :datacite }
  get "/dois/application/vnd.datacite.datacite+json/:id",
      to: "datacite_dois#show",
      constraints: { id: /.+/ },
      defaults: { format: :datacite_json }
  get "/dois/application/vnd.crosscite.crosscite+json/:id",
      to: "datacite_dois#show",
      constraints: { id: /.+/ },
      defaults: { format: :crosscite }
  get "/dois/application/vnd.schemaorg.ld+json/:id",
      to: "datacite_dois#show",
      constraints: { id: /.+/ },
      defaults: { format: :schema_org }
  get "/dois/application/ld+json/:id",
      to: "datacite_dois#show",
      constraints: { id: /.+/ },
      defaults: { format: :schema_org }
  get "/dois/application/vnd.codemeta.ld+json/:id",
      to: "datacite_dois#show",
      constraints: { id: /.+/ },
      defaults: { format: :codemeta }
  get "/dois/application/vnd.citationstyles.csl+json/:id",
      to: "datacite_dois#show",
      constraints: { id: /.+/ },
      defaults: { format: :citeproc }
  get "/dois/application/vnd.jats+xml/:id",
      to: "datacite_dois#show",
      constraints: { id: /.+/ },
      defaults: { format: :jats }
  get "/dois/application/x-bibtex/:id",
      to: "datacite_dois#show",
      constraints: { id: /.+/ },
      defaults: { format: :bibtex }
  get "/dois/application/x-research-info-systems/:id",
      to: "datacite_dois#show",
      constraints: { id: /.+/ },
      defaults: { format: :ris }
  get "/dois/text/csv/:id",
      to: "datacite_dois#show",
      constraints: { id: /.+/ },
      defaults: { format: :csv }
  get "/dois/text/x-bibliography/:id",
      to: "datacite_dois#show",
      constraints: { id: /.+/ },
      defaults: { format: :citation }

  # content negotiation for collections
  get "/dois/application/vnd.datacite.datacite+xml",
      to: "datacite_dois#index", defaults: { format: :datacite }
  get "/dois/application/vnd.datacite.datacite+json",
      to: "datacite_dois#index", defaults: { format: :datacite_json }
  get "/dois/application/vnd.crosscite.crosscite+json",
      to: "datacite_dois#index", defaults: { format: :crosscite }
  get "/dois/application/vnd.schemaorg.ld+json",
      to: "datacite_dois#index", defaults: { format: :schema_org }
  get "/dois/application/ld+json",
      to: "datacite_dois#index", defaults: { format: :schema_org }
  get "/dois/application/vnd.codemeta.ld+json",
      to: "datacite_dois#index", defaults: { format: :codemeta }
  get "/dois/application/vnd.citationstyles.csl+json",
      to: "datacite_dois#index", defaults: { format: :citeproc }
  get "/dois/application/vnd.jats+xml",
      to: "datacite_dois#index", defaults: { format: :jats }
  get "/dois/application/x-bibtex",
      to: "datacite_dois#index", defaults: { format: :bibtex }
  get "/dois/application/x-research-info-systems",
      to: "datacite_dois#index", defaults: { format: :ris }
  get "/dois/text/csv", to: "datacite_dois#index", defaults: { format: :csv }
  get "/dois/text/x-bibliography",
      to: "datacite_dois#index", defaults: { format: :citation }
  get "/providers/text/csv", to: "providers#index", defaults: { format: :csv }
  get "providers/random", to: "providers#random"
  get "repositories/random", to: "repositories#random"
  get "/organizations/text/csv",
      to: "organizations#index", defaults: { format: :csv }
  get "/repositories/text/csv",
      to: "repositories#index", defaults: { format: :csv }

  # manage DOIs
  post "dois/validate", to: "datacite_dois#validate"
  post "dois/undo", to: "datacite_dois#undo"
  post "dois/status", to: "datacite_dois#status"
  post "dois/set-url", to: "datacite_dois#set_url"
  post "dois/delete-test-dois", to: "datacite_dois#delete_test_dois"
  get "dois/random", to: "datacite_dois#random"
  get "dois/:id/get-url", to: "datacite_dois#get_url", constraints: { id: /.+/ }
  get "dois/get-dois", to: "datacite_dois#get_dois"

  get "providers/image/:id", to: "providers#image", constraints: { id: /.+/ }

  get "providers/totals", to: "providers#totals"
  get "clients/totals", to: "clients#totals"
  get "repositories/totals", to: "repositories#totals"
  get "prefixes/totals", to: "prefixes#totals"
  get "/providers/:id/stats", to: "providers#stats"
  get "/clients/:id/stats", to: "clients#stats", constraints: { id: /.+/ }
  get "/repositories/:id/stats",
      to: "repositories#stats", constraints: { id: /.+/ }

  # Reporting
  get "export/organizations",
      to: "exports#organizations", defaults: { format: :csv }
  get "export/repositories",
      to: "exports#repositories", defaults: { format: :csv }
  get "export/contacts", to: "exports#contacts", defaults: { format: :csv }
  get "export/check-indexed-dois", to: "exports#import_dois_not_indexed"

  # Exporting
  post "providers/export", to: "providers#export"
  post "repositories/export", to: "repositories#export"
  post "contacts/export", to: "contacts#export"

  # Monthly Data File access
  get "credentials/datafile", to: "datafile#create_credentials", defaults: { format: :json }

  resources :heartbeat, only: %i[index]

  resources :activities, only: %i[index show], constraints: { id: /.+/ }

  resources :clients, constraints: { id: /.+/ } do
    resources :prefixes, constraints: { id: /.+/ }
    resources :datacite_dois, path: "dois", constraints: { id: /.+/ }
    resources :activities
  end

  resources :repositories, constraints: { id: /.+/ } do
    resources :prefixes, constraints: { id: /.+/ }
    resources :datacite_dois, path: "dois", constraints: { id: /.+/ }
    resources :activities
  end

  resources :reference_repositories, path: "reference-repositories", only: %i[index show], constraints: { id: /.+/ }

  resources :client_prefixes, path: "client-prefixes"
  resources :datacite_dois, path: "dois", constraints: { id: /.+/ } do
    resources :metadata
    resources :media
    resources :activities
    resources :events
  end

  resources :contacts

  constraints(->(req) { req.env["HTTP_ACCEPT"].to_s.include?("version=2") }) do
    resources :events
  end
  constraints(->(req) { req.env["HTTP_ACCEPT"].to_s.exclude?("version=2") }) do
    resources :old_events, path: "events"
  end

  resources :prefixes, constraints: { id: /.+/ }
  resources :provider_prefixes, path: "provider-prefixes"
  resources :random, only: %i[index]

  resources :providers do
    resources :clients, constraints: { id: /.+/ }, shallow: true
    resources :repositories, constraints: { id: /.+/ }, shallow: true
    resources :organizations, constraints: { id: /.+/ }, shallow: true
    resources :datacite_dois, path: "dois", constraints: { id: /.+/ }
    resources :prefixes, constraints: { id: /.+/ }
    resources :contacts
    resources :activities
  end
  resources :providers, constraints: { id: /.+/ }
  resources :repository_prefixes, path: "repository-prefixes"
  resources :resource_types, path: "resource-types", only: %i[show index]

  # custom routes for maintenance tasks
  post ":username", to: "datacite_dois#show", as: :user

  # support for legacy routes
  resources :members, only: %i[show index]
  resources :data_centers,
            only: %i[show index],
            constraints: { id: /.+/ },
            path: "/data-centers"
  resources :works, only: %i[show index], constraints: { id: /.+/ }

  # content negotiation
  resources :index,
            path: "/",
            only: %i[show index],
            constraints: { id: /.+/ },
            format: false

  root to: "index#index"

  # rescue routing errors
  match "*path", to: "index#routing_error", via: :all
end
