Rails.application.routes.draw do
  # jsonapi_resources :datasets
  # jsonapi_resources :allocators
  # jsonapi_resources :prefixes
  # jsonapi_resources :datacentres
  resources :datacentres, constraints: { :id => /.+/ }
  # resources :datasets
  resources :datasets, constraints: { :id => /.+/ }
  resources :prefixes, constraints: { :id => /.+/ }
  resources :allocators
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
