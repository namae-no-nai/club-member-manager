Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "events#index"
  resources :events
  resource :partners, only: [ :new, :create ] do
    collection do
      post :register
    end
  end
  get "/pdfs/generate", to: "pdfs#document"
end
