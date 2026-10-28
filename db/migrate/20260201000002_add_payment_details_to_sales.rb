class AddPaymentDetailsToSales < ActiveRecord::Migration[7.1]
  def change
    add_column :sales, :payment_bank, :string       # transferencia: banco de origen
    add_column :sales, :payment_holder, :string     # transferencia: titular de la cuenta
    add_column :sales, :payment_reference, :string  # transferencia: No. de referencia / tarjeta: código de autorización
    add_column :sales, :card_brand, :string         # tarjeta: Visa, Mastercard, ...
    add_column :sales, :card_last4, :string, limit: 4 # tarjeta: últimos 4 dígitos (nunca el número completo)
  end
end
