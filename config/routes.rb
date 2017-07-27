Rails.application.routes.draw do
  resources :heartbeat, only: [:index]
  resources :index, path: '/', only: [:index]
  resources :datacentres, path: '/id/datacentres', constraints: { :id => /.+/ }
  resources :datasets, path: '/id/datasets', constraints: { :id => /.+/ }
  resources :prefixes, path: '/id/prefixes', constraints: { :id => /.+/ }
  resources :allocators, path: '/id/allocators'
  resources :members, path: '/id/members', controller: 'allocators'
  resources :datacenters, path: '/id/datacenters', controller: 'datacentres'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
