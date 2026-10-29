class InventoryMovementsController < ApplicationController
  def index = @movements = InventoryMovement.includes(:product, :user).order(created_at: :desc).limit(300)
  def new
    @movement = InventoryMovement.new
    @products = Product.active.order(:name)
  end
  def create
    InventoryMovement.transaction do
      product = Product.lock.find(params[:inventory_movement][:product_id])
      qty = Integer(params[:inventory_movement][:quantity], 10)
      type = params[:inventory_movement][:movement_type]
      raise ArgumentError, "La cantidad debe ser mayor que cero." unless qty.positive?
      new_stock = case type
      when "adjustment_in", "return_in" then product.stock + qty
      when "adjustment_out" then product.stock - qty
      else raise ArgumentError, "Tipo de ajuste no permitido."
      end
      raise ArgumentError, "El ajuste no puede dejar existencias negativas." if new_stock.negative?
      product.update!(stock: new_stock)
      InventoryMovement.create!(product: product, user: current_user, movement_type: type, quantity: qty,
        reference_type: "ManualAdjustment", reference_id: product.id, note: params[:inventory_movement][:note])
    end
    redirect_to inventory_movements_path, notice: "Movimiento registrado."
  rescue ArgumentError, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
    redirect_to new_inventory_movement_path, alert: "No se pudo registrar: #{e.message}"
  end
end
