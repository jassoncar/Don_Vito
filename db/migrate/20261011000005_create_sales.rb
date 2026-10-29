class CreateSales < ActiveRecord::Migration[7.2]
  def change
    create_table :sales do |t|
      t.string :reference, null: false
      t.references :customer, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :payment_method, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.decimal :subtotal, precision: 12, scale: 2, null: false, default: 0
      t.decimal :discount, precision: 12, scale: 2, null: false, default: 0
      t.decimal :tax, precision: 12, scale: 2, null: false, default: 0
      t.decimal :total, precision: 12, scale: 2, null: false, default: 0
      t.timestamps
    end
    add_index :sales, :reference, unique: true
    add_index :sales, :created_at
    create_table :sale_items do |t|
      t.references :sale, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.decimal :unit_price, precision: 12, scale: 2, null: false
      t.decimal :subtotal, precision: 12, scale: 2, null: false
      t.timestamps
    end
  end
end
