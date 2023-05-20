Rails.application.routes.draw do
  resources :characters do
    get 'search', on: :collection
  end

  get '/character', to: 'characters#search', defaults: { format: 'json' }

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
