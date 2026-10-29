class SalesController < ApplicationController
  before_action(only: %i[pos search create]) { require_permission!("sales.create") }
  before_action(only: %i[index show receipt]) { require_permission!("sales.view") }
  before_action(only: :cancel) { require_permission!("sales.cancel") }

  def pos
    @restore = []
    @form = {}
    load_pos_data
  end

  def search
    q = params[:q].to_s.strip
    scope = Product.active.where("stock > 0").order(:name).limit(12)
    if q.present?
      like = "%#{Product.sanitize_sql_like(q)}%"
      scope = scope.where("name LIKE :like OR sku LIKE :like OR barcode = :exact", like: like, exact: q)
    end

    render json: scope.map { |p|
      { id: p.id, sku: p.sku, barcode: p.barcode, name: p.name, price: p.sale_price.to_f,
        tax_rate: p.tax_rate.to_f, stock: p.stock, image: p.image_url }
    }
  end

  def index
    scope = Sale.includes(:customer, :user).order(id: :desc)
    scope = scope.where("sales.created_at >= ?", Time.zone.parse(params[:from]).beginning_of_day) if valid_date?(params[:from])
    scope = scope.where("sales.created_at <= ?", Time.zone.parse(params[:to]).end_of_day) if valid_date?(params[:to])
    scope = scope.where(status: params[:status]) if Sale::STATUSES.key?(params[:status])
    scope = scope.where(user_id: params[:user_id]) if params[:user_id].present?
    if params[:q].present?
      like = "%#{Sale.sanitize_sql_like(params[:q].to_s.strip)}%"
      scope = scope.left_joins(:customer).where("sales.code LIKE :q OR customers.name LIKE :q", q: like)
    end

    @sales = paginate(scope)
    @users = User.order(:name)
  end

  def create
    items = raw_items.map { |i| { product_id: i["product_id"].to_i, quantity: i["quantity"].to_i } }
    data = params.permit(:customer_id, :payment_method, :discount, :amount_paid, :notes,
                         :transfer_bank, :transfer_reference, :transfer_holder,
                         :card_brand, :card_last4, :card_auth).to_h.symbolize_keys

    begin
      sale = SaleCreator.call(user: current_user, data: data, items: items)
      redirect_to sale_path(sale), notice: "Venta registrada correctamente."
    rescue SaleCreator::Error, StockService::Error => e
      flash.now[:alert] = e.message
      @form = data
      @restore = items.filter_map do |item|
        product = Product.find_by(id: item[:product_id])
        next unless product

        { id: product.id, sku: product.sku, name: product.name, price: product.sale_price.to_f,
          tax_rate: product.tax_rate.to_f, stock: product.stock, image: product.image_url,
          qty: [item[:quantity], 1].max }
      end
      load_pos_data
      render :pos, status: :unprocessable_entity
    end
  end

  def show
    @sale = Sale.includes(:customer, :user, sale_returns: :user, sale_items: :product).find(params[:id])
  end

  def receipt
    sale = Sale.includes(:customer, :user, sale_items: :product).find(params[:id])
    send_data ReceiptPdf.new(sale).render, filename: "comprobante-#{sale.code}.pdf",
                                           type: "application/pdf", disposition: "inline"
  end

  def cancel
    sale = Sale.find(params[:id])
    reason = params[:cancel_reason].to_s.strip

    if reason.blank?
      return redirect_to sale_path(sale), alert: "Indique el motivo de la anulación."
    end

    Sale.transaction do
      sale.lock!
      raise StockService::Error, "La venta no se puede anular en su estado actual." unless sale.status == "completed"
      raise StockService::Error, "La venta tiene devoluciones; no se puede anular." if sale.sale_items.where("returned_qty > 0").exists?

      sale.sale_items.includes(:product).each do |item|
        StockService.move(item.product, item.quantity, "sale_cancel", sale, notes: "Anulación #{sale.code}")
      end
      sale.update!(status: "cancelled", cancel_reason: reason)
    end

    AuditLog.record("cancelled", sale, description: "Anuló la venta #{sale.code}")
    redirect_to sale_path(sale), notice: "Venta anulada y stock restituido."
  rescue StockService::Error => e
    redirect_to sale_path(params[:id]), alert: e.message
  end

  private

  def load_pos_data
    @customers = Customer.where(is_active: true).order(:name)
  end

  def valid_date?(value)
    Date.iso8601(value.to_s)
    true
  rescue ArgumentError
    false
  end
end
