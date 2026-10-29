class CategoriesController < ApplicationController
  before_action :set_category, only: %i[edit update destroy]
  def index = @categories = Category.order(:name)
  def new = @category = Category.new
  def create
    @category = Category.new(category_params)
    if @category.save; redirect_to categories_path, notice: "Categoría creada."
    else; render :new, status: :unprocessable_entity; end
  end
  def edit; end
  def update
    if @category.update(category_params); redirect_to categories_path, notice: "Categoría actualizada."
    else; render :edit, status: :unprocessable_entity; end
  end
  def destroy
    if @category.products.exists?; @category.update!(active: false)
    else; @category.destroy; end
    redirect_to categories_path, notice: "Categoría procesada."
  end
  private
  def set_category = @category = Category.find(params[:id])
  def category_params = params.require(:category).permit(:name, :description, :active)
end
