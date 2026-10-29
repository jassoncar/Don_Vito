class CreateInventoryAndAudit < ActiveRecord::Migration[7.2]
  def change
    create_table :inventory_movements do |t|
      t.references :product, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :movement_type, null: false
      t.integer :quantity, null: false
      t.string :reference_type, null: false
      t.bigint :reference_id
      t.string :note
      t.timestamps
    end
    add_index :inventory_movements, [:reference_type, :reference_id]
    add_index :inventory_movements, :created_at
    create_table :audit_logs do |t|
      t.references :user, foreign_key: true
      t.string :action, null: false
      t.string :record_type, null: false
      t.bigint :record_id
      t.text :details
      t.timestamps
    end
    add_index :audit_logs, [:record_type, :record_id]
  end
end
