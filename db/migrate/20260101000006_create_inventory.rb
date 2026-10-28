class CreateInventory < ActiveRecord::Migration[7.1]
  def change
    create_table :inventory_adjustments do |t|
      t.string :code
      t.references :product, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :kind, null: false # in, out
      t.integer :quantity, null: false
      t.string :reason, null: false
      t.text :notes
      t.timestamps
    end
    add_index :inventory_adjustments, :code, unique: true

    create_table :stock_movements do |t|
      t.references :product, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :kind, null: false # initial, purchase, sale, sale_cancel, return, adjustment
      t.integer :quantity, null: false # con signo
      t.integer :stock_after, null: false
      t.string :reference_type
      t.bigint :reference_id
      t.string :notes
      t.timestamps
    end
    add_index :stock_movements, %i[reference_type reference_id]
  end
end
