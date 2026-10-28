require "csv"
require "roo"

# Importa productos desde un archivo CSV o Excel (.xlsx). Crea los nuevos y, opcionalmente,
# actualiza los existentes (identificados por SKU). El stock de un producto existente nunca
# se modifica desde la importación (use Ajustes de inventario o Compras).
class ProductImporter
  MAX_ROWS = 2000
  MAX_FILE_SIZE = 5.megabytes

  HEADINGS = ["SKU", "Código de barras", "Nombre", "Categoría", "Marca", "Proveedor", "Costo", "Precio",
              "Impuesto %", "Stock mínimo", "Stock inicial", "Descripción", "Activo"].freeze

  EXAMPLE_ROWS = [
    ["LIC-1001", "7441234567890", "Ron Zacapa 23 años 750 ml", "Ron", "Zacapa", "Distribuidora Central S.A.", 1500, 1950, 15, 3, 12, "Ron premium", "Sí"],
    ["LIC-1002", "", "Cerveza Corona botella 355 ml", "Cerveza", "Corona", "", 36, 52, 15, 24, 96, "", "Sí"]
  ].freeze

  ALIASES = {
    sku: ["sku", "codigo", "codigo sku"],
    barcode: ["codigo de barras", "codigo barras", "barcode", "ean"],
    name: ["nombre", "producto", "name", "descripcion corta"],
    category: ["categoria", "category"],
    brand: ["marca", "brand"],
    supplier: ["proveedor", "supplier"],
    cost: ["costo", "precio de costo", "precio costo", "cost"],
    price: ["precio", "precio de venta", "precio venta", "price"],
    tax: ["impuesto", "impuesto %", "iva", "iva %"],
    min_stock: ["stock minimo", "minimo", "min stock"],
    initial_stock: ["stock inicial", "stock", "existencia", "existencias", "cantidad"],
    description: ["descripcion", "detalle"],
    active: ["activo", "estado"]
  }.freeze

  Result = Struct.new(:created, :updated, :skipped, :errors, keyword_init: true)

  class Error < StandardError; end

  def initialize(file, update_existing: true)
    @file = file
    @update_existing = update_existing
  end

  def call
    rows = read_rows
    result = Result.new(created: 0, updated: 0, skipped: 0, errors: [])

    AuditLog.suppress do
      rows.each do |row|
        begin
          outcome = import_row(row)
          result[outcome] += 1
        rescue ActiveRecord::RecordInvalid => e
          result.errors << { row: row[:_row], message: e.record.errors.full_messages.to_sentence }
        rescue Error => e
          result.errors << { row: row[:_row], message: e.message }
        end
      end
    end

    result
  end

  private

  # --- Lectura -----------------------------------------------------------
  def read_rows
    raise Error, "Seleccione un archivo." unless @file.respond_to?(:original_filename)
    raise Error, "El archivo supera el máximo de 5 MB." if @file.size > MAX_FILE_SIZE

    table = case File.extname(@file.original_filename.to_s).downcase
            when ".csv" then read_csv
            when ".xlsx" then read_xlsx
            else raise Error, "Formato no soportado. Use un archivo .csv o .xlsx (puede descargar la plantilla)."
            end

    header = table.shift
    raise Error, "El archivo está vacío." if header.nil?

    columns = map_columns(header)
    missing = { sku: "SKU", name: "Nombre", category: "Categoría", price: "Precio" }.reject { |key, _| columns.value?(key) }
    raise Error, "Faltan columnas obligatorias: #{missing.values.join(', ')}." if missing.any?

    rows = []
    table.each_with_index do |cells, index|
      next if cells.all? { |cell| cell.to_s.strip.empty? }

      rows << columns.each_with_object({ _row: index + 2 }) { |(position, key), hash| hash[key] = cells[position] }
    end

    raise Error, "No hay filas de datos para importar." if rows.empty?
    raise Error, "El archivo tiene más de #{MAX_ROWS} filas. Divídalo en archivos más pequeños." if rows.size > MAX_ROWS

    rows
  end

  def read_csv
    content = @file.read.to_s.dup.force_encoding("UTF-8")
    content = content.encode("UTF-8", "ISO-8859-1") unless content.valid_encoding?
    content = content.delete_prefix("\uFEFF")
    first_line = content.lines.first.to_s
    separator = first_line.count(";") > first_line.count(",") ? ";" : ","
    CSV.parse(content, col_sep: separator)
  rescue CSV::MalformedCSVError => e
    raise Error, "El CSV no se pudo leer: #{e.message}"
  end

  def read_xlsx
    sheet = Roo::Excelx.new(@file.path, extension: :xlsx, file_warning: :ignore).sheet(0)
    sheet.each_row_streaming(pad_cells: true).map do |row|
      row.map { |cell| cell&.value }
    end
  rescue StandardError => e
    raise Error, "El Excel no se pudo leer (#{e.class}). Verifique que sea un .xlsx válido."
  end

  def normalize(text)
    I18n.transliterate(text.to_s).downcase.gsub(/[^a-z0-9%]+/, " ").strip
  end

  def map_columns(header)
    header.each_with_index.each_with_object({}) do |(title, position), columns|
      normalized = normalize(title)
      key = ALIASES.find { |_, names| names.include?(normalized) }&.first
      columns[position] = key if key && !columns.value?(key)
    end
  end

  # --- Importación de una fila ------------------------------------------
  def import_row(row)
    sku = text(row[:sku]).first(50)
    raise Error, "El SKU es obligatorio." if sku.blank?
    raise Error, "El nombre es obligatorio." if text(row[:name]).blank?
    raise Error, "La categoría es obligatoria." if text(row[:category]).blank?

    price = decimal(row[:price], "Precio")
    raise Error, "El precio es obligatorio." if price.nil?

    existing = Product.find_by(sku: sku)
    return :skipped if existing && !@update_existing

    Product.transaction(requires_new: true) do
      attributes = {
        name: text(row[:name]),
        category: find_or_create(Category, row[:category]),
        brand: row[:brand].present? ? find_or_create(Brand, row[:brand]) : nil,
        supplier: row[:supplier].present? ? find_or_create(Supplier, row[:supplier]) : nil,
        sale_price: price,
        description: text(row[:description]).presence
      }
      attributes[:barcode] = text(row[:barcode]) if row[:barcode].present?
      attributes[:cost_price] = decimal(row[:cost], "Costo") if row[:cost].present?
      attributes[:tax_rate] = decimal(row[:tax], "Impuesto") if row[:tax].present?
      attributes[:min_stock] = integer(row[:min_stock], "Stock mínimo") if row[:min_stock].present?
      attributes[:is_active] = boolean(row[:active]) if row[:active].present?

      if existing
        existing.update!(attributes)
        :updated
      else
        product = Product.new({ sku: sku, cost_price: 0, tax_rate: 15, min_stock: 5, is_active: true }.merge(attributes))
        product.initial_stock = integer(row[:initial_stock], "Stock inicial") if row[:initial_stock].present?
        product.save!
        :created
      end
    end
  end

  def text(value)
    value = value.to_i if value.is_a?(Float) && value == value.to_i # 12345.0 -> 12345 (códigos numéricos de Excel)
    value.to_s.strip
  end

  def decimal(value, label)
    return nil if value.to_s.strip.empty?

    cleaned = value.to_s.strip.delete("^0-9.,-")
    cleaned = cleaned.include?(",") && !cleaned.include?(".") ? cleaned.tr(",", ".") : cleaned.delete(",")
    number = BigDecimal(cleaned)
    raise Error, "#{label} no puede ser negativo." if number.negative?

    number
  rescue ArgumentError
    raise Error, "#{label} no es un número válido (\"#{value}\")."
  end

  def integer(value, label)
    number = decimal(value, label)
    raise Error, "#{label} debe ser un número entero." unless number == number.to_i

    number.to_i
  end

  def boolean(value)
    !%w[no n 0 false falso inactivo].include?(normalize(value))
  end

  def find_or_create(model, name)
    name = text(name).first(255)
    model.where("LOWER(name) = ?", name.downcase).first || model.create!(name: name)
  end
end
