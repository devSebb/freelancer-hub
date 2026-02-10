Rails.application.routes.draw do
  devise_for :users

  # Authenticated routes
  authenticate :user do
    get "dashboard", to: "dashboard#show"
    resource :settings, only: [ :show, :update ]

    # Full CRUD
    resources :clients
    resources :proposals do
      member do
        post :send_proposal
        post :save_as_template
        get :export_pdf
        get :preview_pdf
      end
    end

    resources :proposal_templates

    resources :invoices do
      member do
        post :send_invoice
        get :export_pdf
        get :preview_pdf
      end
    end
  end

  # Public proposal viewing (no auth required)
  get "p/:token", to: "public_proposals#show", as: :public_proposal
  post "p/:token/accept", to: "public_proposals#accept", as: :accept_public_proposal

  # Public invoice viewing (no auth required)
  get "i/:token", to: "public_invoices#show", as: :public_invoice

  # Landing page for guests, dashboard for authenticated users
  root to: "pages#home"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
