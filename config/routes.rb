Rails.application.routes.draw do
  root :to => 'index#index'

  # authentication
  post 'token', :to => 'sessions#create'

  # send reset link
  post 'reset', :to => 'sessions#reset'

  # manage DOIs
  post 'dois/validate', :to => 'dois#validate'
  post 'dois/status', :to => 'dois#status'
  post 'dois/set-state', :to => 'dois#set_state'
  post 'dois/set-minted', :to => 'dois#set_minted'
  post 'dois/set-url', :to => 'dois#set_url'
  post 'dois/delete-test-dois', :to => 'dois#delete_test_dois'
  get 'dois/random', :to => 'dois#random'

  # manage prefixes, keep database in sync for changes via MDS
  post 'clients/set-test-prefix', :to => 'clients#set_test_prefix'
  post 'providers/set-test-prefix', :to => 'providers#set_test_prefix'
  post 'client-prefixes/set-created', :to => 'client_prefixes#set_created'
  post 'client-prefixes/set-provider', :to => 'client_prefixes#set_provider'
  post 'provider-prefixes/set-created', :to => 'provider_prefixes#set_created'

  resources :heartbeat, only: [:index]

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

  # re3data
  resources :repositories, only: [:show, :index]
  get "/repositories/:id/badge", to: "repositories#badge", format: :svg

  resources :resource_types, path: 'resource-types', only: [:show, :index]

  # custom routes for maintenance tasks
  post ':username', to: 'dois#show', as: :user

  # support for legacy routes
  resources :members, only: [:show, :index]
  resources :data_centers, only: [:show, :index], constraints: { :id => /.+/ }, path: "/data-centers"

  # content negotiation
  resources :index, path: '/', constraints: { :id => /.+/ }, only: [:show, :index]

  # rescue routing errors
  #match "*path", to: "index#routing_error", via: :all
end
