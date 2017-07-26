Rails.application.routes.draw do
  resources :heartbeat, only: [:index]
  resources :index, path: '/', only: [:index]
  resources :datacentres, constraints: { :id => /.+/ }
  resources :datasets, constraints: { :id => /.+/ }
  resources :prefixes, constraints: { :id => /.+/ }
  resources :allocators
  resources :members, controller: 'allocators'
  resources :datacenters, controller: 'datacentres'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
