class CreateCatalog < ActiveRecord::Migration[7.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.string :description
      t.boolean :is_active, null: false, default: true
      t.timestamps
    end
    add_index :categories, :name, unique: true

    create_table :brands do |t|
      t.string :name, null: false
      t.string :description
      t.boolean :is_active, null: false, default: true
      t.timestamps
    end
    add_index :brands, :name, unique: true

    create_table :suppliers do |t|
      t.string :name, null: false
      t.string :contact_name
      t.string :email
      t.string :phone
      t.string :address
      t.string :tax_id
      t.boolean :is_active, null: false, default: true
      t.timestamps
    end

    create_table :customers do |t|
      t.string :name, null: false
      t.string :email
      t.string :phone
      t.string :address
      t.string :tax_id
      t.boolean :is_active, null: false, default: true
      t.timestamps
    end

    create_table :products do |t|
      t.string :sku, null: false
      t.string :barcode
      t.string :name, null: false
      t.text :description
      t.references :category, null: false, foreign_key: true
      t.references :brand, foreign_key: true
      t.references :supplier, foreign_key: true
      t.decimal :cost_price, precision: 12, scale: 2, null: false, default: 0
      t.decimal :sale_price, precision: 12, scale: 2, null: false, default: 0
      t.integer :stock, null: false, default: 0
      t.integer :min_stock, null: false, default: 5
      t.decimal :tax_rate, precision: 5, scale: 2, null: false, default: 0
      t.boolean :is_active, null: false, default: true
      t.timestamps
    end
    add_index :products, :sku, unique: true
    add_index :products, :barcode, unique: true
  end
end
