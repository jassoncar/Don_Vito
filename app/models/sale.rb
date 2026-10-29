class Sale < ApplicationRecord
  include Auditable
  include Codeable

  STATUSES = { "completed" => "Completada", "cancelled" => "Anulada", "returned" => "Devuelta" }.freeze
  PAYMENT_METHODS = { "cash" => "Efectivo", "card" => "Tarjeta", "transfer" => "Transferencia" }.freeze
  CARD_BRANDS = ["Visa", "Mastercard", "American Express", "Otra"].freeze
  BANK_SUGGESTIONS = ["BAC", "Banpro", "Lafise", "Avanz", "Ficohsa", "Banco Atlántida"].freeze

  belongs_to :customer, optional: true
  belongs_to :user
  has_many :sale_items, dependent: :destroy
  has_many :sale_returns

  def status_label
    STATUSES[status] || status
  end

  def payment_label
    PAYMENT_METHODS[payment_method] || payment_method
  end

  # Texto con los datos del pago electrónico (nunca guarda el número completo de tarjeta).
  def payment_detail
    case payment_method
    when "transfer"
      ["Banco: #{payment_bank}", "Ref.: #{payment_reference}",
       (payment_holder.present? ? "Titular: #{payment_holder}" : nil)].compact.join(" · ")
    when "card"
      ["#{card_brand} ****#{card_last4}", (payment_reference.present? ? "Aut.: #{payment_reference}" : nil)].compact.join(" · ")
    end
  end
end
