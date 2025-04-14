Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "events#index"
  resources :events, only: %i[ index new create ] do
    collection do
      get "register/:partner_id", to: "events#register", as: "register"
      get :filter
      get :generate_pdf

      get :last_records_one
      get :last_records_two
      get :last_records_three
    end
  end

  resources :sessions, only: %i[ new create destroy ] do
    collection do
      post :callback
    end
  end

  resources :registrations, only: %i[ new create ] do
    collection do
      post :callback
    end
  end

  resources :credentials, only: %i[ index new create destroy] do
    collection do
      post :callback
    end
  end

  resources :weapons, only: %i[ index new create ]

  resources :partners, only: %i[ new create ] do
    collection do
      post :create
      post :webauthn_create_callback
    end
  end

  get "/pdfs/generate", to: "pdfs#document"
end
