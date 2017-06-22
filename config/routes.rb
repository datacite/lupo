Rails.application.routes.draw do
  # jsonapi_resources :datasets
  # jsonapi_resources :allocators
  # jsonapi_resources :prefixes
  # jsonapi_resources :datacentres
  resources :datacentres
  resources :datasets
  resources :prefixes
  resources :allocators
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
