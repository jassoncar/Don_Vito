require "prawn"
require "prawn/table"

class ReportPdf
  def initialize(report)
    @report = report
  end

  def render
    pdf = Prawn::Document.new(page_size: "A4", page_layout: :landscape, margin: 30)

    logo = Rails.root.join("public", "images", "logo-light.png")
    if File.exist?(logo)
      pdf.image logo.to_s, height: 46
    else
      pdf.text PdfSupport.clean(Setting.get("company_name", "Licorería")), size: 16, style: :bold
    end
    pdf.move_down 4
    pdf.text PdfSupport.clean(@report[:title]), size: 12, style: :bold
    period = @report[:uses_dates] ? "Período: #{@report[:from]} a #{@report[:to]} - " : ""
    pdf.text "#{period}Generado: #{Time.current.strftime('%d/%m/%Y %H:%M')}", size: 8, color: "666666"

    if @report[:summary].present?
      pdf.move_down 6
      pdf.text PdfSupport.clean(@report[:summary].map { |label, value| "#{label}: #{value}" }.join("    ")), size: 9
    end

    pdf.move_down 8
    rows = [@report[:headings].map { |h| PdfSupport.clean(h) }]
    @report[:rows].each { |row| rows << row.map { |cell| PdfSupport.cell(cell) } }
    numeric = @report[:rows].first&.each_index&.select { |i| @report[:rows].first[i].is_a?(Numeric) } || []

    pdf.table(rows, header: true, width: pdf.bounds.width, cell_style: { size: 7, padding: 3 }) do
      row(0).font_style = :bold
      row(0).background_color = "EEE8D8"
      numeric.each { |i| columns(i).align = :right }
    end

    pdf.render
  end
end
