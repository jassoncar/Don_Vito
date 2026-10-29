Rails.application.routes.draw do
  devise_for :users
  root "dashboard#index"
  resources :products
  resources :categories
  resources :brands
  resources :suppliers
  resources :customers
  resources :purchases do
    member { patch :receive }
  end
  resources :sales, only: %i[index show new create]
  resources :inventory_movements, only: %i[index new create]
  get "reports/inventory", to: "reports#inventory", as: :reports_inventory
  get "reports/low_stock", to: "reports#low_stock", as: :reports_low_stock
  get "reports/sales", to: "reports#sales", as: :reports_sales
  get "reports/purchases", to: "reports#purchases", as: :reports_purchases
  get "reports/movements", to: "reports#movements", as: :reports_movements
  resources :users, only: %i[index edit update]
end
