require "prawn"
require "prawn/table"

class ReceiptPdf
  def initialize(sale)
    @sale = sale
  end

  def render
    sale = @sale
    helpers = ApplicationController.helpers
    pdf = Prawn::Document.new(page_size: "A5", margin: 28)

    logo = Rails.root.join("public", "images", "logo-light.png")
    if File.exist?(logo)
      pdf.image logo.to_s, height: 64, position: :center
    else
      pdf.text PdfSupport.clean(Setting.get("company_name", "Licorería")), size: 16, style: :bold, align: :center
    end
    { "RUC" => Setting.get("company_tax_id"), nil => Setting.get("company_address"), "Tel" => Setting.get("company_phone") }.each do |label, value|
      next if value.blank?

      pdf.text PdfSupport.clean(label ? "#{label}: #{value}" : value), size: 9, align: :center
    end

    pdf.move_down 10
    pdf.text "Comprobante: #{sale.code}", size: 10, style: :bold
    pdf.text "Fecha: #{sale.created_at.strftime('%d/%m/%Y %H:%M')}", size: 9
    pdf.text PdfSupport.clean("Cliente: #{sale.customer&.name || 'Consumidor final'}"), size: 9
    pdf.text PdfSupport.clean("Atendió: #{sale.user&.name}"), size: 9
    pdf.text "Pago: #{sale.payment_label}", size: 9
    pdf.text PdfSupport.clean(sale.payment_detail), size: 9 if sale.payment_detail.present?

    if sale.status == "cancelled"
      pdf.move_down 6
      pdf.fill_color "B91C1C"
      pdf.text "VENTA ANULADA", size: 18, style: :bold, align: :center
      pdf.fill_color "000000"
    end

    pdf.move_down 8
    rows = [%w[Producto Cant. Precio Total]]
    sale.sale_items.each do |item|
      rows << [PdfSupport.clean(item.product&.name), item.quantity.to_s,
               helpers.number_with_precision(item.unit_price, precision: 2, delimiter: ",", separator: "."),
               helpers.number_with_precision(item.total, precision: 2, delimiter: ",", separator: ".")]
    end
    pdf.table(rows, header: true, width: pdf.bounds.width, cell_style: { size: 9, padding: 3, borders: [:bottom] }) do
      row(0).font_style = :bold
      columns(1..3).align = :right
    end

    pdf.move_down 8
    totals = [
      ["Subtotal", helpers.money(sale.subtotal)],
      ["Impuesto", helpers.money(sale.tax)],
      ["Descuento", "- #{helpers.money(sale.discount)}"],
      ["TOTAL", helpers.money(sale.total)],
      ["Recibido", helpers.money(sale.amount_paid)],
      ["Cambio", helpers.money(sale.change_amount)]
    ].map { |label, value| [label, PdfSupport.clean(value)] }
    pdf.table(totals, position: :right, cell_style: { size: 9, padding: 2, borders: [] }) do
      columns(1).align = :right
      row(3).font_style = :bold
    end

    pdf.move_down 14
    pdf.text PdfSupport.clean(Setting.get("receipt_footer", "¡Gracias por su compra!")), size: 9, align: :center, color: "666666"
    pdf.render
  end
end
