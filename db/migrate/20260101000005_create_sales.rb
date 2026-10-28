class CreateSales < ActiveRecord::Migration[7.1]
  def change
    create_table :sales do |t|
      t.string :code
      t.references :customer, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :payment_method, null: false, default: "cash" # cash, card, transfer
      t.decimal :subtotal, precision: 12, scale: 2, null: false, default: 0
      t.decimal :tax, precision: 12, scale: 2, null: false, default: 0
      t.decimal :discount, precision: 12, scale: 2, null: false, default: 0
      t.decimal :total, precision: 12, scale: 2, null: false, default: 0
      t.decimal :amount_paid, precision: 12, scale: 2, null: false, default: 0
      t.decimal :change_amount, precision: 12, scale: 2, null: false, default: 0
      t.string :status, null: false, default: "completed" # completed, cancelled, returned
      t.string :cancel_reason
      t.text :notes
      t.timestamps
    end
    add_index :sales, :code, unique: true

    create_table :sale_items do |t|
      t.references :sale, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.integer :returned_qty, null: false, default: 0
      t.decimal :unit_price, precision: 12, scale: 2, null: false
      t.decimal :tax_rate, precision: 5, scale: 2, null: false, default: 0
      t.decimal :total, precision: 12, scale: 2, null: false # incluye impuesto
      t.timestamps
    end

    create_table :sale_returns do |t|
      t.string :code
      t.references :sale, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :reason, null: false
      t.decimal :total, precision: 12, scale: 2, null: false, default: 0
      t.timestamps
    end
    add_index :sale_returns, :code, unique: true

    create_table :sale_return_items do |t|
      t.references :sale_return, null: false, foreign_key: true
      t.references :sale_item, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.timestamps
    end
  end
end
