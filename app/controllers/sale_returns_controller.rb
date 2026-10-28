class SaleReturnsController < ApplicationController
  before_action(only: %i[index show]) { require_permission!("returns.view") }
  before_action(only: %i[new create]) { require_permission!("returns.create") }

  def index
    @returns = paginate(SaleReturn.includes(:sale, :user).order(id: :desc))
  end

  def show
    @return = SaleReturn.includes(:sale, :user, sale_return_items: :product).find(params[:id])
  end

  def new
    @sale = Sale.includes(:customer, sale_items: :product).find(params[:sale_id])
    if @sale.status == "cancelled"
      redirect_to sale_path(@sale), alert: "No se pueden registrar devoluciones de una venta anulada."
    end
  end

  def create
    sale = Sale.find(params[:sale_id])
    reason = params[:reason].to_s.strip
    rows = raw_items.map { |i| { sale_item_id: i["sale_item_id"].to_i, quantity: i["quantity"].to_i } }
                    .select { |r| r[:quantity] > 0 }

    raise StockService::Error, "Indique el motivo de la devolución." if reason.blank?
    raise StockService::Error, "Indique la cantidad a devolver de al menos un producto." if rows.empty?
    raise StockService::Error, "Hay productos repetidos en la devolución." if rows.map { |r| r[:sale_item_id] }.uniq.size != rows.size

    sale_return = nil
    Sale.transaction do
      sale.lock!
      raise StockService::Error, "La venta está anulada." if sale.status == "cancelled"

      items = sale.sale_items.includes(:product).index_by(&:id)
      gross = sale.subtotal + sale.tax
      factor = gross.positive? ? sale.total / gross : BigDecimal("1")
      lines = []
      total = BigDecimal("0")

      rows.each do |row|
        item = items[row[:sale_item_id]]
        raise StockService::Error, "Un producto no pertenece a esta venta." unless item
        if row[:quantity] > item.returnable
          raise StockService::Error, "Solo se pueden devolver #{item.returnable} unidad(es) de «#{item.product.name}»."
        end

        amount = ((item.total / item.quantity) * factor * row[:quantity]).round(2)
        total += amount
        lines << { item: item, quantity: row[:quantity], amount: amount }
      end

      sale_return = SaleReturn.create!(sale: sale, user: current_user, reason: reason, total: total.round(2))

      lines.each do |line|
        sale_return.sale_return_items.create!(sale_item: line[:item], product: line[:item].product,
                                              quantity: line[:quantity], amount: line[:amount])
        line[:item].update_column(:returned_qty, line[:item].returned_qty + line[:quantity])
        StockService.move(line[:item].product, line[:quantity], "return", sale_return, notes: "Devolución de #{sale.code}")
      end

      sale_return.assign_code!("DEV")

      # Si todo fue devuelto, la venta queda como "Devuelta".
      pending = sale.sale_items.reload.to_a.sum { |i| i.quantity - i.returned_qty }
      sale.update!(status: "returned") if pending.zero?
    end

    redirect_to return_path(sale_return), notice: "Devolución registrada y stock actualizado."
  rescue StockService::Error => e
    @sale = Sale.includes(:customer, sale_items: :product).find(params[:sale_id])
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end
end
