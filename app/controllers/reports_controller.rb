require "csv"

class ReportsController < ApplicationController
  # clave => [título, descripción, usa rango de fechas]
  TYPES = {
    "sales" => ["Ventas", "Detalle de ventas en el rango de fechas.", true],
    "top_products" => ["Productos más vendidos", "Unidades e ingresos por producto.", true],
    "purchases" => ["Compras", "Órdenes de compra en el rango de fechas.", true],
    "returns" => ["Devoluciones", "Devoluciones registradas en el rango de fechas.", true],
    "inventory" => ["Inventario valorizado", "Existencias actuales y su valor.", false],
    "low_stock" => ["Stock bajo", "Productos en o por debajo del stock mínimo.", false]
  }.freeze

  before_action { require_permission!("reports.view") }

  helper_method :report_types

  def index
    @from = Time.zone.today.beginning_of_month.to_s
    @to = Time.zone.today.to_s
  end

  def show
    type = params[:type].to_s
    return head :not_found unless TYPES.key?(type)

    from = parse_date(params[:from]) || Time.zone.today.beginning_of_month
    to = parse_date(params[:to]) || Time.zone.today
    to = from if to < from

    @report = send("build_#{type}", from, to)
    @report.merge!(type: type, uses_dates: TYPES[type][2], from: from, to: to)
    filename = "reporte-#{type}-#{Time.current.strftime('%Y%m%d-%H%M%S')}"

    case params[:format_type].to_s
    when "pdf"
      send_data ReportPdf.new(@report).render, filename: "#{filename}.pdf", type: "application/pdf"
    when "excel"
      send_data excel_data(@report), filename: "#{filename}.xlsx",
                                     type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    when "csv"
      csv = CSV.generate { |out| out << @report[:headings]; @report[:rows].each { |row| out << row } }
      send_data "\uFEFF#{csv}", filename: "#{filename}.csv", type: "text/csv; charset=utf-8"
    else
      render :show
    end
  end

  private

  def report_types = TYPES

  def parse_date(value)
    Date.iso8601(value.to_s)
  rescue ArgumentError
    nil
  end

  def range(from, to)
    from.beginning_of_day..to.end_of_day
  end

  def excel_data(report)
    package = Axlsx::Package.new
    package.workbook.add_worksheet(name: report[:title].first(31).gsub(%r{[\\/*?:\[\]]}, "")) do |sheet|
      sheet.add_row report[:headings]
      report[:rows].each { |row| sheet.add_row row.map { |cell| cell.is_a?(BigDecimal) ? cell.to_f : cell } }
    end
    package.to_stream.read
  end

  def fmt_money(value)
    ApplicationController.helpers.money(value)
  end

  def build_sales(from, to)
    sales = Sale.includes(:customer, :user).where(created_at: range(from, to)).order(:id)
    valid = sales.reject { |s| s.status == "cancelled" }

    {
      title: "Reporte de ventas",
      headings: ["Código", "Fecha", "Cliente", "Vendedor", "Pago", "Detalle de pago", "Subtotal", "Impuesto", "Descuento", "Total", "Estado"],
      rows: sales.map do |s|
        [s.code, s.created_at.strftime("%Y-%m-%d %H:%M"), s.customer&.name || "Consumidor final", s.user&.name,
         s.payment_label, s.payment_detail.to_s, s.subtotal.to_f, s.tax.to_f, s.discount.to_f, s.total.to_f, s.status_label]
      end,
      summary: { "Ventas válidas" => valid.size, "Total vendido" => fmt_money(valid.sum(&:total)) }
    }
  end

  def build_top_products(from, to)
    data = SaleItem.joins(:sale, :product)
                   .where.not(sales: { status: "cancelled" })
                   .where(sales: { created_at: range(from, to) })
                   .group("products.id", "products.sku", "products.name")
                   .order(Arel.sql("SUM(sale_items.quantity - sale_items.returned_qty) DESC"))
                   .limit(50)
                   .pluck("products.sku", "products.name",
                          Arel.sql("SUM(sale_items.quantity - sale_items.returned_qty)"),
                          Arel.sql("SUM(sale_items.total)"))

    {
      title: "Productos más vendidos",
      headings: ["SKU", "Producto", "Unidades netas", "Ingresos"],
      rows: data.map { |sku, name, units, revenue| [sku, name, units.to_i, revenue.to_f] },
      summary: { "Productos listados" => data.size }
    }
  end

  def build_purchases(from, to)
    purchases = Purchase.includes(:supplier, :user).where(ordered_at: from..to).order(:id)
    received = purchases.select { |p| p.status == "received" }

    {
      title: "Reporte de compras",
      headings: ["Código", "Fecha orden", "Proveedor", "Registrado por", "Estado", "Recibida", "Total"],
      rows: purchases.map do |p|
        [p.code, p.ordered_at.strftime("%Y-%m-%d"), p.supplier&.name, p.user&.name, p.status_label,
         p.received_at&.strftime("%Y-%m-%d %H:%M") || "", p.total.to_f]
      end,
      summary: { "Órdenes recibidas" => received.size, "Total recibido" => fmt_money(received.sum(&:total)) }
    }
  end

  def build_returns(from, to)
    returns = SaleReturn.includes(:sale, :user).where(created_at: range(from, to)).order(:id).to_a

    {
      title: "Reporte de devoluciones",
      headings: ["Código", "Fecha", "Venta", "Motivo", "Registrado por", "Total devuelto"],
      rows: returns.map do |r|
        [r.code, r.created_at.strftime("%Y-%m-%d %H:%M"), r.sale&.code, r.reason, r.user&.name, r.total.to_f]
      end,
      summary: { "Devoluciones" => returns.size, "Total devuelto" => fmt_money(returns.sum(&:total)) }
    }
  end

  def build_inventory(_from, _to)
    products = Product.includes(:category).order(:name).to_a

    {
      title: "Inventario valorizado",
      headings: ["SKU", "Producto", "Categoría", "Stock", "Mínimo", "Costo", "Precio", "Valor a costo"],
      rows: products.map do |p|
        [p.sku, p.name, p.category&.name, p.stock, p.min_stock, p.cost_price.to_f, p.sale_price.to_f,
         (p.stock * p.cost_price).round(2).to_f]
      end,
      summary: {
        "Unidades en existencia" => products.sum(&:stock),
        "Valor total a costo" => fmt_money(products.sum { |p| p.stock * p.cost_price })
      }
    }
  end

  def build_low_stock(_from, _to)
    products = Product.includes(:category, :supplier).low_stock.order(:stock)

    {
      title: "Productos con stock bajo",
      headings: ["SKU", "Producto", "Categoría", "Proveedor", "Stock", "Mínimo"],
      rows: products.map { |p| [p.sku, p.name, p.category&.name, p.supplier&.name, p.stock, p.min_stock] },
      summary: { "Productos a reponer" => products.size }
    }
  end
end
