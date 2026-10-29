class CreateParties < ActiveRecord::Migration[7.2]
  def change
    create_table :suppliers do |t|
      t.string :name, null: false
      t.string :contact_name
      t.string :phone
      t.string :email
      t.text :address
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :suppliers, :name
    create_table :customers do |t|
      t.string :name, null: false
      t.string :phone
      t.string :email
      t.text :address
      t.timestamps
    end
    add_index :customers, :name
  end
end
