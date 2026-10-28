Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#index"

  get "login", to: "sessions#new", as: :login
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout

  get "dashboard", to: "dashboard#index", as: :dashboard
  resource :profile, only: %i[edit update], controller: "profile"

  # Importación masiva de productos
  get "products/import", to: "product_imports#new", as: :new_product_import
  post "products/import", to: "product_imports#create", as: :product_import
  get "products/import/template", to: "product_imports#template", as: :product_import_template

  # CRUD genéricos
  resources :products, :categories, :brands, :suppliers, :customers, :users, :roles, except: :show

  # Compras
  resources :purchases, only: %i[index new create show] do
    member do
      post :receive
      post :cancel
    end
  end

  # Ventas / POS
  get "pos", to: "sales#pos", as: :pos
  get "pos/search", to: "sales#search", as: :pos_search
  resources :sales, only: %i[index create show] do
    member do
      get :receipt
      post :cancel
    end
    resources :returns, only: %i[new create], controller: "sale_returns"
  end

  # Devoluciones
  get "returns", to: "sale_returns#index", as: :returns
  get "returns/:id", to: "sale_returns#show", as: :return

  # Inventario
  get "inventory", to: "inventory#index", as: :inventory
  get "inventory/:id", to: "inventory#show", as: :inventory_product
  resources :adjustments, only: %i[index new create]

  # Reportes, configuración y auditoría
  get "reports", to: "reports#index", as: :reports
  get "reports/:type", to: "reports#show", as: :report
  resource :settings, only: %i[edit update]
  get "audit", to: "audit_logs#index", as: :audit
end
