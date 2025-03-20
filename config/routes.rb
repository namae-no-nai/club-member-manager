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

  resource :session, only: [:new, :create, :destroy] do
    post :callback
  end

  resource :registration, only: [:new, :create] do
    post :callback
  end

  resources :credentials, only: %i[ index new create destroy] do
    post :callback, on: :collection
  end
  
  resources :weapons, only: %i[ index new create ] 

  resource :partners, only: %i[ new create ] do
    collection do
      post :register
    end
  end
  get "/pdfs/generate", to: "pdfs#document"
end
