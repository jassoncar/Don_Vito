class DashboardController < ApplicationController
  def index
    @products_count = Product.count
    @low_stock_count = Product.active.low_stock.count
    @inventory_value = Product.sum("stock * cost_price")
    @recent_movements = InventoryMovement.includes(:product, :user).order(created_at: :desc).limit(8)
    @recent_sales = Sale.includes(:customer, :user).order(created_at: :desc).limit(5)
  end
end
