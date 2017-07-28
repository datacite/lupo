Rails.application.routes.draw do
  resources :heartbeat, only: [:index]
  resources :index, path: '/', only: [:index]
  resources :datacentres, constraints: { :id => /.+/ }
  resources :datasets, constraints: { :id => /.+/ }
  resources :prefixes, constraints: { :id => /.+/ }
  resources :allocators
  resources :members, path: '/members', controller: 'allocators'
  resources :data_centers, path: "/data-centers", controller: 'datacentres'
end
