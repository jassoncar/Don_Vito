class CreateCatalog < ActiveRecord::Migration[7.2]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :categories, "LOWER(name)", unique: true, name: "index_categories_on_lower_name"
    create_table :brands do |t|
      t.string :name, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :brands, "LOWER(name)", unique: true, name: "index_brands_on_lower_name"
    create_table :products do |t|
      t.string :sku, null: false
      t.string :barcode
      t.string :name, null: false
      t.text :description
      t.references :category, null: false, foreign_key: true
      t.references :brand, foreign_key: true
      t.decimal :cost_price, precision: 12, scale: 2, null: false, default: 0
      t.decimal :sale_price, precision: 12, scale: 2, null: false, default: 0
      t.integer :stock, null: false, default: 0
      t.integer :minimum_stock, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :products, :sku, unique: true
    add_index :products, :barcode, unique: true
    add_index :products, :name
    add_index :products, :stock
  end
end
