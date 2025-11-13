Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "events#index"
  resources :events, only: %i[ index new edit update create destroy] do
    collection do
      get "register/:partner_id", to: "events#register", as: "register"
      get :filter
      get :generate_pdf
    end
  end

  get :last_records, to: "records#last_records"
  get :last_weapons_records, to: "records#last_weapons_records"
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

  resources :poc, only: %i[ new create show index] do
    collection do
      post :verify
    end
  end

  resources :credentials, only: %i[ index new create destroy] do
    collection do
      post :callback
    end
  end

  resources :weapons, only: %i[ index new edit update create ] do
    member do
      patch :archive
    end
  end

  resources :partners, only: %i[ new edit update create ] do
    collection do
      get :bulk
      post :csv_create
      post :create
      post :webauthn_create_callback
    end

    member do
      get "/biometric_proof_images/", to: "biometric_proof_images#show", as: :biometric_proof_image
      post "/biometric_proof_images/", to: "biometric_proof_images#create", as: :biometric_proof_images
      delete "/biometric_proof_images/", to: "biometric_proof_images#destroy"
    end
  end

  get "/csv/generate", to: "csv#document"
end
