class PurchasesController < ApplicationController
  before_action(only: %i[index show]) { require_permission!("purchases.view") }
  before_action(only: %i[new create]) { require_permission!("purchases.create") }
  before_action(only: :receive) { require_permission!("purchases.receive") }
  before_action(only: :cancel) { require_permission!("purchases.cancel") }

  def index
    scope = Purchase.includes(:supplier, :user).order(id: :desc)
    scope = scope.where(status: params[:status]) if Purchase::STATUSES.key?(params[:status])
    if params[:q].present?
      like = "%#{Purchase.sanitize_sql_like(params[:q].to_s.strip)}%"
      scope = scope.left_joins(:supplier).where("purchases.code LIKE :q OR suppliers.name LIKE :q", q: like)
    end
    @purchases = paginate(scope)
  end

  def new
    @old_items = []
    load_form_data
  end

  def create
    rows = raw_items.map do |item|
      { product_id: item["product_id"].to_i, quantity: item["quantity"].to_i, unit_cost: to_decimal(item["unit_cost"]) }
    end
    supplier = Supplier.find_by(id: params[:supplier_id])
    ordered_at = (Date.iso8601(params[:ordered_at].to_s) rescue nil)

    @errors = []
    @errors << "Seleccione un proveedor." unless supplier
    @errors << "Indique una fecha válida." unless ordered_at
    @errors << "Agregue al menos un producto a la orden." if rows.empty?
    if rows.map { |r| r[:product_id] }.uniq.size != rows.size
      @errors << "Hay productos repetidos en la orden."
    end
    if rows.any? { |r| r[:product_id].zero? || !Product.exists?(r[:product_id]) || r[:quantity] < 1 || r[:unit_cost].nil? || r[:unit_cost].negative? }
      @errors << "Revise los productos: cada uno requiere cantidad entera mayor a cero y costo válido."
    end

    if @errors.any?
      @old_items = rows.map { |r| { product_id: r[:product_id], quantity: r[:quantity], unit_cost: r[:unit_cost].to_f } }
      load_form_data
      return render :new, status: :unprocessable_entity
    end

    purchase = nil
    Purchase.transaction do
      total = rows.sum { |r| (r[:quantity] * r[:unit_cost]).round(2) }
      purchase = Purchase.create!(supplier: supplier, user: current_user, status: "ordered",
                                  ordered_at: ordered_at, total: total, notes: params[:notes].presence)
      rows.each do |r|
        purchase.purchase_items.create!(product_id: r[:product_id], quantity: r[:quantity],
                                        unit_cost: r[:unit_cost], total: (r[:quantity] * r[:unit_cost]).round(2))
      end
      purchase.assign_code!("OC")
    end

    redirect_to purchase_path(purchase), notice: "Orden de compra creada. Cuando llegue la mercadería, márquela como recibida."
  end

  def show
    @purchase = Purchase.includes(:supplier, :user, purchase_items: :product).find(params[:id])
  end

  def receive
    purchase = Purchase.find(params[:id])

    Purchase.transaction do
      purchase.lock!
      raise StockService::Error, "Solo se pueden recibir órdenes en estado «Ordenada»." unless purchase.status == "ordered"

      purchase.purchase_items.includes(:product).each do |item|
        StockService.move(item.product, item.quantity, "purchase", purchase, notes: "Recepción #{purchase.code}")
        # El último costo de compra pasa a ser el costo del producto (sin disparar auditoría).
        Product.where(id: item.product_id).update_all(cost_price: item.unit_cost)
      end

      purchase.update!(status: "received", received_at: Time.current)
    end

    AuditLog.record("received", purchase, description: "Recibió orden de compra #{purchase.code}")
    redirect_to purchase_path(purchase), notice: "Orden recibida: el inventario fue actualizado."
  rescue StockService::Error => e
    redirect_to purchase_path(params[:id]), alert: e.message
  end

  def cancel
    purchase = Purchase.find(params[:id])

    if purchase.status == "ordered"
      purchase.update!(status: "cancelled")
      redirect_to purchase_path(purchase), notice: "Orden cancelada."
    else
      redirect_to purchase_path(purchase), alert: "Solo se pueden cancelar órdenes en estado «Ordenada»."
    end
  end

  private

  def load_form_data
    @suppliers = Supplier.where(is_active: true).order(:name)
    @products = Product.active.order(:name).map do |p|
      { id: p.id, label: "#{p.sku} - #{p.name}", cost: p.cost_price.to_f }
    end
  end
end
