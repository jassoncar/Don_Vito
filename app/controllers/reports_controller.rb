class ReportsController < ApplicationController
    def inventory
      @products = Product.includes(:category).order(:name)
      respond_to do |format|
        format.html { render "reports/inventory" }
        format.csv do
          send_data CSV.generate(headers: true) { |csv| csv << %w[SKU Producto Categoría Existencias Costo Precio Valor]; @products.each { |p| csv << [p.sku,p.name,p.category.name,p.stock,p.cost_price,p.sale_price,p.stock*p.cost_price] } },
          filename: "inventario-#{Date.current}.csv"
        end
      end
    end
    def low_stock
      @products = Product.active.low_stock.order(:stock)
      respond_to do |format|
        format.html
        format.csv { send_data CSV.generate(headers: true) { |csv| csv << %w[SKU Producto Existencias Mínimo]; @products.each { |p| csv << [p.sku,p.name,p.stock,p.minimum_stock] } }, filename: "inventario-bajo.csv" }
      end
    end
    def sales
      @sales = Sale.where(created_at: (params[:from].presence || Date.current.beginning_of_month)..(params[:to].presence || Date.current).to_date.end_of_day).order(created_at: :desc)
      respond_to do |format|
        format.html
        format.csv { send_data CSV.generate(headers: true) { |csv| csv << %w[Referencia Fecha Cliente Usuario Subtotal Descuento Impuesto Total]; @sales.each { |s| csv << [s.reference,s.created_at,s.customer&.name,s.user.email,s.subtotal,s.discount,s.tax,s.total] } }, filename: "ventas.csv" }
      end
    end
    def purchases
      @purchases = Purchase.includes(:supplier).order(created_at: :desc)
      respond_to do |format|
        format.html
        format.csv { send_data CSV.generate(headers: true) { |csv| csv << %w[Referencia Proveedor Estado Total Fecha]; @purchases.each { |p| csv << [p.reference,p.supplier.name,p.status,p.total,p.created_at] } }, filename: "compras.csv" }
      end
    end
    def movements
      @movements = InventoryMovement.includes(:product, :user).order(created_at: :desc)
      respond_to do |format|
        format.html
        format.csv { send_data CSV.generate(headers: true) { |csv| csv << %w[Fecha Producto Tipo Cantidad Usuario Nota]; @movements.each { |m| csv << [m.created_at,m.product.name,m.movement_type,m.quantity,m.user.email,m.note] } }, filename: "movimientos.csv" }
      end
    end
  end
