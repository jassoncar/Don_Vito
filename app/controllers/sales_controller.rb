class SalesController < ApplicationController
  def index = @sales = Sale.includes(:customer, :user).order(created_at: :desc)
  def show = @sale = Sale.includes(sale_items: :product).find(params[:id])
  def new
    @products = Product.active.where("stock > 0").order(:name)
    @customers = Customer.order(:name)
  end
  def create
    sale = nil
    Sale.transaction do
      sale = Sale.create!(reference: "VEN-#{Time.current.strftime('%Y%m%d%H%M%S%L')}",
        user: current_user, customer_id: params[:customer_id].presence,
        payment_method: params[:payment_method], subtotal: 0, discount: params[:discount].presence || 0,
        tax: params[:tax].presence || 0, total: 0, status: :completed)
      subtotal = 0.to_d
      (params[:items] || []).each do |row|
        next if row[:product_id].blank?
        qty = Integer(row[:quantity], 10)
        raise ArgumentError, "La cantidad debe ser mayor que cero." unless qty.positive?
        product = Product.lock.find(row[:product_id])
        raise ArgumentError, "Existencias insuficientes para #{product.name}." if product.stock < qty
        price = product.sale_price
        line = price * qty
        sale.sale_items.create!(product: product, quantity: qty, unit_price: price, subtotal: line)
        product.update!(stock: product.stock - qty)
        InventoryMovement.create!(product: product, user: current_user, movement_type: :sale_out,
          quantity: qty, reference_type: "Sale", reference_id: sale.id, note: "Venta #{sale.reference}")
        subtotal += line
      end
      raise ArgumentError, "Agrega al menos un producto." if sale.sale_items.empty?
      discount = BigDecimal(params[:discount].presence || "0")
      tax = BigDecimal(params[:tax].presence || "0")
      raise ArgumentError, "Descuento e impuesto no pueden ser negativos." if discount.negative? || tax.negative?
      sale.update!(subtotal: subtotal, discount: discount, tax: tax, total: [subtotal - discount, 0].max + tax)
    end
    audit!("create", sale)
    redirect_to sale_path(sale), notice: "Operación registrada correctamente."
  rescue ArgumentError, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
    redirect_to new_sale_path, alert: "No se pudo registrar la venta: #{e.message}"
  end
end
