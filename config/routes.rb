Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "events#index"
  resources :events, only: %i[ index new edit update create ] do
    collection do
      get "register/:partner_id", to: "events#register", as: "register"
      get :filter
      get :generate_pdf
    end
  end

  get :last_records, to: "records#last_records"
  get :last_partner_records, to: "records#last_partner_records"
  get :last_events_records, to: "records#last_events_records"

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

  resources :partners, only: %i[ new edit update create ] do
    collection do
      post :create
      post :webauthn_create_callback
    end
  end

  get "/pdfs/generate", to: "pdfs#document"
end
