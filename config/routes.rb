Rails.application.routes.draw do
  resources :heartbeat, only: [:index]
  resources :index, path: '/lupo', only: [:index]
  resources :datacentres, path: '/lupo/datacentres',  constraints: { :id => /.+/ }
  resources :datasets,  path: '/lupo/datasets', constraints: { :id => /.+/ }
  resources :prefixes,  path: '/lupo/prefixes', constraints: { :id => /.+/ }
  resources :allocators, path: '/lupo/allocators'
  resources :members, path: '/lupo/members',  controller: 'allocators'
  resources :datacenters,  path: '/lupo/datacenters', controller: 'datacentres'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
