Rails.application.routes.draw do
  resources :metadata
  resources :media
  root :to => 'index#index'

  resources :heartbeat, only: [:index]
  resources :index, path: '/', only: [:index]
  resources :status, only: [:index]

  resources :clients, constraints: { :id => /.+?(?=\/)/} do
    member do
      get :getpassword
    end
  end

  resources :clients, constraints: { :id => /.+/ } do
    resources :prefixes, constraints: { :id => /.+/ }, shallow: true
    resources :client_prefixes, path: 'client-prefixes'
    resources :dois, constraints: { :id => /.+/ }
  end

  resources :client_prefixes, path: 'client-prefixes'
  resources :datasets, constraints: { :id => /.+/ }
  resources :dois, constraints: { :id => /.+/ }
  resources :prefixes, constraints: { :id => /.+/ }
  resources :provider_prefixes, path: 'provider-prefixes'

  resources :providers do
    resources :clients, constraints: { :id => /.+/ }, shallow: true
    resources :dois, constraints: { :id => /.+/ }
    resources :prefixes, constraints: { :id => /.+/ }, shallow: true
    resources :provider_prefixes, path: 'provider-prefixes'

    member do
      post :getpassword
    end
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
  resources :works, only: [:show, :index], constraints: { :id => /.+/ }

  # rescue routing errors
  match "*path", to: "index#routing_error", via: :all
end
