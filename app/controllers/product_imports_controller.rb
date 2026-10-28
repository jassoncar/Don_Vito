require "csv"

class ProductImportsController < ApplicationController
  before_action { require_permission!("products.create") }

  def new
    @result = nil
  end

  def create
    update_existing = params[:update_existing] == "1" && can?("products.edit")

    begin
      @result = ProductImporter.new(params[:file], update_existing: update_existing).call
      AuditLog.record("created", description: "Importó productos desde archivo: #{@result.created} creados, " \
                                               "#{@result.updated} actualizados, #{@result.errors.size} con error")
      flash.now[:notice] = "Importación terminada: #{@result.created} creados, #{@result.updated} actualizados." if @result.created + @result.updated > 0
    rescue ProductImporter::Error => e
      @errors = [e.message]
    end

    render :new, status: (@errors.present? ? :unprocessable_entity : :ok)
  end

  def template
    if params[:formato] == "csv"
      csv = CSV.generate do |out|
        out << ProductImporter::HEADINGS
        ProductImporter::EXAMPLE_ROWS.each { |row| out << row }
      end
      send_data "\uFEFF#{csv}", filename: "plantilla-productos.csv", type: "text/csv; charset=utf-8"
    else
      package = Axlsx::Package.new
      package.workbook.add_worksheet(name: "Productos") do |sheet|
        sheet.add_row ProductImporter::HEADINGS, style: package.workbook.styles.add_style(b: true)
        ProductImporter::EXAMPLE_ROWS.each { |row| sheet.add_row row }
      end
      send_data package.to_stream.read, filename: "plantilla-productos.xlsx",
                                        type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    end
  end
end
