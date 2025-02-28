Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "events#index"
  resources :events
  get '/pdfs/generate', to: 'pdfs#generate'
end
