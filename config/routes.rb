Rails.application.routes.draw do
  resources :members
  resources :heartbeat, only: [:index]
  resources :index, path: '/', only: [:index]
  resources :datacenters, constraints: { :id => /.+/ }
  resources :datasets, constraints: { :id => /.+/ }
  resources :prefixes, constraints: { :id => /.+/ }
  # resources :allocators
  # resources :members, path: '/members', controller: 'allocators'
  resources :data_centers, path: "/data-centers", controller: 'datacenters'
end
