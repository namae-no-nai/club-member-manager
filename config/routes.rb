Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "members#index"
  resources :members
  get '/pdfs/generate', to: 'pdfs#generate'
end
