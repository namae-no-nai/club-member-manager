Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "events#index"
  resources :events, only: %i[ index new create ] do
    collection do
      get "register/:partner_id", to: "events#register", as: "register"
      get :filter
      get :generate_pdf
    end
  end

  resource :weapons, only: %i[ new create ]

  resource :partners, only: %i[ new create ] do
    collection do
      post :register
    end
  end
  get "/pdfs/generate", to: "pdfs#document"
end
