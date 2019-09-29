Rails.application.routes.draw do
  post "/graphql", to: "graphql#execute"
  get "/graphql", to: "index#method_not_allowed"

  root :to => 'index#index'

  # authentication
  post 'token', :to => 'sessions#create_token'

  # authentication via openid connect in load balancer
  post 'oidc-token', :to => 'sessions#create_oidc_token'

  # send reset link
  post 'reset', :to => 'sessions#reset'

  # content negotiation
  get '/dois/application/vnd.datacite.datacite+xml/:id', :to => 'dois#show', constraints: { :id => /.+/ }, defaults: { format: :datacite }
  get '/dois/application/vnd.datacite.datacite+json/:id', :to => 'dois#show', constraints: { :id => /.+/ }, defaults: { format: :datacite_json }
  get '/dois/application/vnd.crosscite.crosscite+json/:id', :to => 'dois#show', constraints: { :id => /.+/ }, defaults: { format: :crosscite }
  get '/dois/application/vnd.schemaorg.ld+json/:id', :to => 'dois#show', constraints: { :id => /.+/ }, defaults: { format: :schema_org }
  get '/dois/application/vnd.codemeta.ld+json/:id', :to => 'dois#show', constraints: { :id => /.+/ }, defaults: { format: :codemeta }
  get '/dois/application/vnd.citationstyles.csl+json/:id', :to => 'dois#show', constraints: { :id => /.+/ }, defaults: { format: :citeproc }
  get '/dois/application/vnd.jats+xml/:id', :to => 'dois#show', constraints: { :id => /.+/ }, defaults: { format: :jats }
  get '/dois/application/x-bibtex/:id', :to => 'dois#show', constraints: { :id => /.+/ }, defaults: { format: :bibtex }
  get '/dois/application/x-research-info-systems/:id', :to => 'dois#show', constraints: { :id => /.+/ }, defaults: { format: :ris }
  get '/dois/text/csv/:id', :to => 'dois#show', constraints: { :id => /.+/ }, defaults: { format: :csv }
  get '/dois/text/x-bibliography/:id', :to => 'dois#show', constraints: { :id => /.+/ }, defaults: { format: :citation }

  # content negotiation for collections
  get '/dois/application/vnd.datacite.datacite+xml', :to => 'dois#index', defaults: { format: :datacite }
  get '/dois/application/vnd.datacite.datacite+json', :to => 'dois#index', defaults: { format: :datacite_json }
  get '/dois/application/vnd.crosscite.crosscite+json', :to => 'dois#index', defaults: { format: :crosscite }
  get '/dois/application/vnd.schemaorg.ld+json', :to => 'dois#index', defaults: { format: :schema_org }
  get '/dois/application/vnd.codemeta.ld+json', :to => 'dois#index', defaults: { format: :codemeta }
  get '/dois/application/vnd.citationstyles.csl+json', :to => 'dois#index', defaults: { format: :citeproc }
  get '/dois/application/vnd.jats+xml', :to => 'dois#index', defaults: { format: :jats }
  get '/dois/application/x-bibtex', :to => 'dois#index', defaults: { format: :bibtex }
  get '/dois/application/x-research-info-systems', :to => 'dois#index', defaults: { format: :ris }
  get '/dois/text/csv', :to => 'dois#index', defaults: { format: :csv }
  get '/dois/text/x-bibliography', :to => 'dois#index', defaults: { format: :citation }
  get '/providers/text/csv', :to => 'providers#index', defaults: { format: :csv }
  get 'providers/random', :to => 'providers#random'
  get '/organizations/text/csv', :to => 'organizations#index', defaults: { format: :csv }
  get '/repositories/text/csv', :to => 'repositories#index', defaults: { format: :csv }


  # manage DOIs
  post 'dois/validate', :to => 'dois#validate'
  post 'dois/undo', :to => 'dois#undo'
  post 'dois/status', :to => 'dois#status'
  post 'dois/set-url', :to => 'dois#set_url'
  post 'dois/delete-test-dois', :to => 'dois#delete_test_dois'
  get 'dois/random', :to => 'dois#random'
  get 'dois/:id/get-url', :to => 'dois#get_url', constraints: { :id => /.+/ }
  get 'dois/get-dois', :to => 'dois#get_dois'
  get 'providers/totals', :to => 'providers#totals'
  get 'clients/totals', :to => 'clients#totals'
  get 'prefixes/totals', :to => 'prefixes#totals'

  resources :heartbeat, only: [:index]
  resources :index, only: [:index]

  resources :activities, only: [:index, :show]

  resources :clients, constraints: { id: /.+/ } do
    resources :prefixes, constraints: { id: /.+/ }
    resources :dois, constraints: { id: /.+/ }
  end

  resources :repositories, constraints: { id: /.+/ } do
    resources :prefixes, constraints: { id: /.+/ }
    resources :dois, constraints: { id: /.+/ }
  end

  resources :client_prefixes, path: "client-prefixes"
  resources :dois, constraints: { id: /.+/ } do
    resources :metadata
    resources :media
    resources :activities
    resources :events
  end

  constraints(-> (req) { req.env["HTTP_ACCEPT"].to_s.include?("version=2") }) do
    resources :events
  end
  constraints(-> (req) { req.env["HTTP_ACCEPT"].to_s.exclude?("version=2") }) do
    resources :old_events, path: "events"
  end

  resources :prefixes, constraints: { :id => /.+/ }
  resources :provider_prefixes, path: 'provider-prefixes'
  resources :random, only: [:index]

  resources :providers do
    resources :clients, constraints: { :id => /.+/ }, shallow: true
    resources :repositories, constraints: { :id => /.+/ }, shallow: true
    resources :organizations, constraints: { :id => /.+/ }, shallow: true
    resources :dois, constraints: { :id => /.+/ }
    resources :prefixes, constraints: { :id => /.+/ }
  end
  resources :providers, constraints: { :id => /.+/ }
  resources :resource_types, path: 'resource-types', only: [:show, :index]

  # custom routes for maintenance tasks
  post ':username', to: 'dois#show', as: :user

  # support for legacy routes
  resources :members, only: [:show, :index]
  resources :data_centers, only: [:show, :index], constraints: { id: /.+/ }, path: "/data-centers"
  resources :works, only: [:show, :index], constraints: { id: /.+/ }

  # rescue routing errors
  #match "*path", to: "index#routing_error", via: :all
end
