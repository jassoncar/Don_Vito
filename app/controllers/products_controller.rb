class ProductsController < ApplicationController
  before_action :set_product, only: %i[show edit update destroy]
  def index
    @products = Product.includes(:category, :brand).order(:name)
    @products = @products.where("name LIKE ? OR sku LIKE ? OR barcode LIKE ?", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%") if params[:q].present?
    @products = @products.low_stock if params[:low_stock].present?
  end
  def show; end
  def new; @product = Product.new(active: true, stock: 0, minimum_stock: 5); end
  def create
    @product = Product.new(product_params)
    if @product.save
      audit!("create", @product); redirect_to @product, notice: "Producto creado correctamente."
    else
      render :new, status: :unprocessable_entity
    end
  end
  def edit; end
  def update
    if @product.update(product_params)
      audit!("update", @product); redirect_to @product, notice: "Producto actualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end
  def destroy
    @product.update(active: false)
    audit!("deactivate", @product)
    redirect_to products_path, notice: "Producto desactivado."
  end
  private
  def set_product = @product = Product.find(params[:id])
  def product_params = params.require(:product).permit(:sku, :barcode, :name, :description, :category_id, :brand_id, :cost_price, :sale_price, :stock, :minimum_stock, :active)
end
