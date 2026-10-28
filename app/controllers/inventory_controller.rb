class InventoryController < ApplicationController
  before_action { require_permission!("inventory.view") }

  def index
    scope = Product.includes(:category).order(:name)
    if params[:q].present?
      like = "%#{Product.sanitize_sql_like(params[:q].to_s.strip)}%"
      scope = scope.where("products.name LIKE :q OR products.sku LIKE :q OR products.barcode LIKE :q", q: like)
    end
    scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?
    scope = scope.low_stock if params[:low] == "1"

    @products = paginate(scope, per: 20)
    @categories = Category.order(:name)
    @totals = {
      units: Product.sum(:stock),
      cost_value: Product.sum("stock * cost_price"),
      sale_value: Product.sum("stock * sale_price")
    }
  end

  def show
    @product = Product.includes(:category, :brand).find(params[:id])
    @movements = paginate(@product.stock_movements.includes(:user).order(id: :desc), per: 20)
  end
end
