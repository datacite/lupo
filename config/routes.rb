Rails.application.routes.draw do
  resources :metadata
  resources :media
  root :to => 'index#index'

  resources :heartbeat, only: [:index]
  resources :index, path: '/', only: [:index]
  resources :status, only: [:index]

  resources :clients, path: "/clients", constraints: { :id => /.+/ }
  resources :datasets, constraints: { :id => /.+/ }
  resources :dois, path: "/dois", constraints: { :id => /.+/ }
  resources :prefixes, constraints: { :id => /.+/ }
  resources :providers, constraints: { :id => /.+/ }

  # rescue routing errors
  # match "*path", to: "index#routing_error", via: :all
end
