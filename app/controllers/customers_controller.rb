class CustomersController < ApplicationController
  before_action :set_customer, only: %i[show edit update destroy]
  def index = @customers = Customer.order(:name)
  def show; end
  def new = @customer = Customer.new
  def create
    @customer = Customer.new(customer_params)
    if @customer.save; redirect_to customers_path, notice: "Cliente creado."
    else; render :new, status: :unprocessable_entity; end
  end
  def edit; end
  def update
    if @customer.update(customer_params); redirect_to customers_path, notice: "Cliente actualizado."
    else; render :edit, status: :unprocessable_entity; end
  end
  def destroy
    @customer.destroy
    redirect_to customers_path, notice: "Cliente eliminado."
  end
  private
  def set_customer = @customer = Customer.find(params[:id])
  def customer_params = params.require(:customer).permit(:name, :phone, :email, :address)
end
