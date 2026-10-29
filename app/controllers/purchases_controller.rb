class PurchasesController < ApplicationController
  def index = @purchases = Purchase.includes(:supplier, :user).order(created_at: :desc)
  def show = @purchase = Purchase.includes(purchase_items: :product).find(params[:id])
  def new
    @purchase = Purchase.new
    @suppliers = Supplier.where(active: true)
    @products = Product.active.order(:name)
  end
  def create
    @purchase = Purchase.new(supplier_id: params[:purchase][:supplier_id], user: current_user,
      reference: "COM-#{Time.current.strftime('%Y%m%d%H%M%S%L')}", status: :draft, total: 0)
    items = params[:items] || []
    Purchase.transaction do
      @purchase.save!
      items.each do |item|
        next if item[:product_id].blank? || item[:quantity].to_i <= 0
        product = Product.lock.find(item[:product_id])
        @purchase.purchase_items.create!(product: product, quantity: item[:quantity], unit_cost: item[:unit_cost])
      end
      raise ActiveRecord::RecordInvalid, @purchase if @purchase.purchase_items.empty?
      @purchase.recalculate_total!
    end
    audit!("create", @purchase)
    redirect_to @purchase, notice: "Compra registrada. Recibe la mercancía para actualizar existencias."
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
    @suppliers = Supplier.where(active: true); @products = Product.active.order(:name)
    flash.now[:alert] = "No se pudo registrar la compra: #{e.message}"
    render :new, status: :unprocessable_entity
  end
  def receive
    purchase = Purchase.find(params[:id])
    Purchase.transaction do
      purchase.lock!
      raise ActiveRecord::RecordInvalid, purchase unless purchase.draft?
      purchase.purchase_items.includes(:product).each do |item|
        product = Product.lock.find(item.product_id)
        product.update!(stock: product.stock + item.quantity)
        InventoryMovement.create!(product: product, user: current_user, movement_type: :purchase_in,
          quantity: item.quantity, reference_type: "Purchase", reference_id: purchase.id, note: "Recepción de compra #{purchase.reference}")
      end
      purchase.update!(status: :received)
    end
    audit!("receive", purchase)
    redirect_to purchase, notice: "Compra recibida y existencias actualizadas."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to purchase, alert: "No se pudo recibir: #{e.message}"
  end
end
