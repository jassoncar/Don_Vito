class CreatePurchases < ActiveRecord::Migration[7.2]
  def change
    create_table :purchases do |t|
      t.string :reference, null: false
      t.references :supplier, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.decimal :total, precision: 12, scale: 2, null: false, default: 0
      t.text :notes
      t.timestamps
    end
    add_index :purchases, :reference, unique: true
    create_table :purchase_items do |t|
      t.references :purchase, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.decimal :unit_cost, precision: 12, scale: 2, null: false
      t.timestamps
    end
  end
end
