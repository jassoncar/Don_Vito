class StockMovement < ApplicationRecord
  KINDS = {
    "initial" => "Stock inicial", "purchase" => "Compra recibida", "sale" => "Venta",
    "sale_cancel" => "Venta anulada", "return" => "Devolución", "adjustment" => "Ajuste"
  }.freeze

  belongs_to :product
  belongs_to :user, optional: true

  def kind_label
    KINDS[kind] || kind
  end
end
