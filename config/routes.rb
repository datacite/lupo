Rails.application.routes.draw do
  resources :heartbeat, only: [:index]
  resources :index, path: '/', only: [:index]
  resources :datacenters, path: "/data-centers", constraints: { :id => /.+/ }
  resources :datasets, constraints: { :id => /.+/ }
  resources :prefixes, constraints: { :id => /.+/ }
  resources :members, constraints: { :id => /.+/ }
end
