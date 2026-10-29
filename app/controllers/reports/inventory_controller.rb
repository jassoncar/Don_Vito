module Reports
  class InventoryController < ApplicationController
    def index
      @products = Product.includes(:category).order(:name)
      respond_to do |format|
        format.html
        format.csv do
          send_data CSV.generate(headers: true) { |csv| csv << %w[SKU Producto Categoría Existencias Costo Precio Valor]; @products.each { |p| csv << [p.sku,p.name,p.category.name,p.stock,p.cost_price,p.sale_price,p.stock*p.cost_price] } },
            filename: "inventario-#{Date.current}.csv"
        end
      end
    end
  end
end
