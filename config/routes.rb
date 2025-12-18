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

  resources :partners, only: %i[ new edit show update create ] do
    collection do
      get :bulk
      post :csv_create
      post :create
      post :webauthn_create_callback
    end
  end

  resources :fingerprint_verifications, only: [ :index, :destroy ] do
    collection do
      post :search
    end
  end

  post :capture_fingerprint_verification, to: "fingerprint_verifications#capture"
  post :compare_fingerprint_verification, to: "fingerprint_verifications#compare"

  get "/csv/generate", to: "csv#document"
end
