Rails.application.routes.draw do
  root :to => 'index#index'

  # authentication
  post 'token', :to => 'sessions#create'

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
  get '/dois/text/x-bibliography/:id', :to => 'dois#show', constraints: { :id => /.+/ }, defaults: { format: :citation }

  get '/dois/application/vnd.datacite.datacite+xml', :to => 'dois#index', defaults: { format: :datacite }
  get '/dois/application/vnd.datacite.datacite+json', :to => 'dois#index', defaults: { format: :datacite_json }
  get '/dois/application/vnd.crosscite.crosscite+json', :to => 'dois#index', defaults: { format: :crosscite }
  get '/dois/application/vnd.schemaorg.ld+json', :to => 'dois#index', defaults: { format: :schema_org }
  get '/dois/application/vnd.codemeta.ld+json', :to => 'dois#index', defaults: { format: :codemeta }
  get '/dois/application/vnd.citationstyles.csl+json', :to => 'dois#index', defaults: { format: :citeproc }
  get '/dois/application/vnd.jats+xml', :to => 'dois#index', defaults: { format: :jats }
  get '/dois/application/x-bibtex', :to => 'dois#index', defaults: { format: :bibtex }
  get '/dois/application/x-research-info-systems', :to => 'dois#index', defaults: { format: :ris }
  get '/dois/text/x-bibliography', :to => 'dois#index', defaults: { format: :citation }

  # manage DOIs
  post 'dois/validate', :to => 'dois#validate'
  post 'dois/status', :to => 'dois#status'
  post 'dois/set-minted', :to => 'dois#set_minted'
  post 'dois/set-url', :to => 'dois#set_url'
  post 'dois/delete-test-dois', :to => 'dois#delete_test_dois'
  get 'dois/random', :to => 'dois#random'
  get 'dois/:id/get-url', :to => 'dois#get_url', constraints: { :id => /.+/ }
  get 'dois/get-dois', :to => 'dois#get_dois'

  # manage prefixes, keep database in sync for changes via MDS
  post 'client-prefixes/set-created', :to => 'client_prefixes#set_created'
  post 'client-prefixes/set-provider', :to => 'client_prefixes#set_provider'
  post 'provider-prefixes/set-created', :to => 'provider_prefixes#set_created'

  resources :heartbeat, only: [:index]
  resources :index, only: [:index]

  resources :clients, constraints: { :id => /.+/ } do
    resources :prefixes, constraints: { :id => /.+/ }
    resources :dois, constraints: { :id => /.+/ }
  end

  resources :client_prefixes, path: 'client-prefixes'
  resources :dois, constraints: { :id => /.+/ } do
    resources :metadata
    resources :media
  end
  resources :prefixes, constraints: { :id => /.+/ }
  resources :provider_prefixes, path: 'provider-prefixes'
  resources :random, only: [:index]

  resources :providers do
    resources :clients, constraints: { :id => /.+/ }, shallow: true
    resources :dois, constraints: { :id => /.+/ }
    resources :prefixes, constraints: { :id => /.+/ }
  end
  resources :providers, constraints: { :id => /.+/ }

  resources :resource_types, path: 'resource-types', only: [:show, :index]

  # custom routes for maintenance tasks
  post ':username', to: 'dois#show', as: :user

  # support for legacy routes
  resources :members, only: [:show, :index]
  resources :data_centers, only: [:show, :index], constraints: { :id => /.+/ }, path: "/data-centers"
  resources :works, only: [:show, :index], constraints: { :id => /.+/ }

  # rescue routing errors
  #match "*path", to: "index#routing_error", via: :all
end
