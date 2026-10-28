class AdjustmentsController < ApplicationController
  before_action(only: :index) { require_permission!("inventory.view") }
  before_action(only: %i[new create]) { require_permission!("inventory.adjust") }

  def index
    @adjustments = paginate(InventoryAdjustment.includes(:product, :user).order(id: :desc))
  end

  def new
    load_data
  end

  def create
    product = Product.find_by(id: params[:product_id])
    kind = params[:kind].to_s
    quantity = params[:quantity].to_i
    reason = params[:reason].to_s

    errors = []
    errors << "Seleccione un producto." unless product
    errors << "Tipo de ajuste inválido." unless %w[in out].include?(kind)
    errors << "La cantidad debe ser un entero mayor a cero." if quantity < 1
    errors << "Motivo inválido." unless InventoryAdjustment::REASONS.include?(reason)

    if errors.empty?
      begin
        InventoryAdjustment.transaction do
          adjustment = InventoryAdjustment.create!(product: product, user: current_user, kind: kind,
                                                   quantity: quantity, reason: reason, notes: params[:notes].presence)
          StockService.move(product, kind == "in" ? quantity : -quantity, "adjustment", adjustment, notes: reason)
          adjustment.assign_code!("AJ")
        end
        return redirect_to adjustments_path, notice: "Ajuste de inventario registrado."
      rescue StockService::Error => e
        errors << e.message
      end
    end

    @errors = errors
    load_data
    render :new, status: :unprocessable_entity
  end

  private

  def load_data
    @products = Product.order(:name)
    @reasons = InventoryAdjustment::REASONS
  end
end
