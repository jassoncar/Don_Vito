# Registra una venta completa: recalcula precios e impuestos desde la base de datos
# (nunca confía en el navegador), valida stock y descuenta inventario.
class SaleCreator
  class Error < StandardError; end

  def self.call(user:, data:, items:)
    new(user: user, data: data, items: items).call
  end

  def initialize(user:, data:, items:)
    @user = user
    @data = data
    @items = items
  end

  def call
    raise Error, "Agregue al menos un producto a la venta." if @items.empty?

    ids = @items.map { |item| item[:product_id] }
    raise Error, "Hay productos repetidos en la venta." if ids.uniq.size != ids.size
    raise Error, "Las cantidades deben ser números enteros mayores a cero." if @items.any? { |item| item[:quantity] < 1 }

    method = @data[:payment_method].to_s
    raise Error, "Método de pago inválido." unless Sale::PAYMENT_METHODS.key?(method)

    payment_details = payment_details_for(method)

    customer_id = @data[:customer_id].presence
    raise Error, "Cliente inválido." if customer_id && !Customer.exists?(customer_id)

    Sale.transaction do
      products = Product.active.where(id: ids).index_by(&:id)
      subtotal = BigDecimal("0")
      tax = BigDecimal("0")
      lines = []

      @items.each do |item|
        product = products[item[:product_id]]
        raise Error, "Un producto de la venta ya no está disponible." unless product

        line_subtotal = (product.sale_price * item[:quantity]).round(2)
        line_tax = (line_subtotal * product.tax_rate / 100).round(2)
        subtotal += line_subtotal
        tax += line_tax
        lines << { product: product, quantity: item[:quantity], unit_price: product.sale_price,
                   tax_rate: product.tax_rate, total: line_subtotal + line_tax }
      end

      gross = (subtotal + tax).round(2)
      discount = [[decimal(@data[:discount]) || BigDecimal("0"), BigDecimal("0")].max, gross].min
      total = (gross - discount).round(2)
      paid = method == "cash" ? (decimal(@data[:amount_paid]) || total) : total
      raise Error, "El monto recibido es menor al total de la venta." if paid < total

      sale = Sale.create!(
        customer_id: customer_id, user: @user, payment_method: method,
        subtotal: subtotal.round(2), tax: tax.round(2), discount: discount.round(2),
        total: total, amount_paid: paid, change_amount: (paid - total).round(2),
        status: "completed", notes: @data[:notes].presence,
        **payment_details
      )

      lines.each do |line|
        sale.sale_items.create!(product: line[:product], quantity: line[:quantity],
                                unit_price: line[:unit_price], tax_rate: line[:tax_rate], total: line[:total])
        StockService.move(line[:product], -line[:quantity], "sale", sale)
      end

      sale.assign_code!("VTA")
      sale
    end
  end

  private

  # Datos mínimos para conciliar pagos electrónicos. Por seguridad NO se piden ni se guardan
  # el número completo de la tarjeta, la fecha de vencimiento ni el CVV.
  def payment_details_for(method)
    case method
    when "transfer"
      bank = @data[:transfer_bank].to_s.strip
      reference = @data[:transfer_reference].to_s.strip
      holder = @data[:transfer_holder].to_s.strip
      raise Error, "Transferencia: indique el banco de origen." if bank.blank?
      raise Error, "Transferencia: indique el número de referencia (mínimo 4 caracteres)." if reference.length < 4

      { payment_bank: bank.first(100), payment_reference: reference.first(100), payment_holder: holder.presence&.first(150) }
    when "card"
      brand = @data[:card_brand].to_s.strip
      last4 = @data[:card_last4].to_s.strip
      auth = @data[:card_auth].to_s.strip
      raise Error, "Tarjeta: seleccione la marca." unless Sale::CARD_BRANDS.include?(brand)
      raise Error, "Tarjeta: indique los últimos 4 dígitos." unless last4.match?(/\A\d{4}\z/)
      raise Error, "Tarjeta: indique el código de autorización del voucher." if auth.blank?

      { card_brand: brand, card_last4: last4, payment_reference: auth.first(100) }
    else
      {}
    end
  end

  def decimal(value)
    text = value.to_s.strip
    return nil if text.empty?

    number = BigDecimal(text)
    number.finite? ? number : nil
  rescue ArgumentError
    nil
  end
end
