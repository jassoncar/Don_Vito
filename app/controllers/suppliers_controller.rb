class SuppliersController < ApplicationController
  before_action :set_supplier, only: %i[show edit update destroy]
  def index = @suppliers = Supplier.order(:name)
  def show; end
  def new = @supplier = Supplier.new(active: true)
  def create
    @supplier = Supplier.new(supplier_params)
    if @supplier.save; redirect_to suppliers_path, notice: "Proveedor creado."
    else; render :new, status: :unprocessable_entity; end
  end
  def edit; end
  def update
    if @supplier.update(supplier_params); redirect_to suppliers_path, notice: "Proveedor actualizado."
    else; render :edit, status: :unprocessable_entity; end
  end
  def destroy
    @supplier.update!(active: false)
    redirect_to suppliers_path, notice: "Proveedor desactivado."
  end
  private
  def set_supplier = @supplier = Supplier.find(params[:id])
  def supplier_params = params.require(:supplier).permit(:name, :contact_name, :phone, :email, :address, :active)
end
