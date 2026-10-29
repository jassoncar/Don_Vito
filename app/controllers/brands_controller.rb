class BrandsController < ApplicationController
  before_action :set_brand, only: %i[edit update destroy]
  def index = @brands = Brand.order(:name)
  def new = @brand = Brand.new
  def create
    @brand = Brand.new(brand_params)
    if @brand.save; redirect_to brands_path, notice: "Marca creada."
    else; render :new, status: :unprocessable_entity; end
  end
  def edit; end
  def update
    if @brand.update(brand_params); redirect_to brands_path, notice: "Marca actualizada."
    else; render :edit, status: :unprocessable_entity; end
  end
  def destroy
    @brand.products.exists? ? @brand.update!(active: false) : @brand.destroy
    redirect_to brands_path, notice: "Marca procesada."
  end
  private
  def set_brand = @brand = Brand.find(params[:id])
  def brand_params = params.require(:brand).permit(:name, :active)
end
