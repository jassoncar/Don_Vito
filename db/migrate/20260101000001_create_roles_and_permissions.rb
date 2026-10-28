class CreateRolesAndPermissions < ActiveRecord::Migration[7.1]
  def change
    create_table :roles do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :description
      t.timestamps
    end
    add_index :roles, :name, unique: true
    add_index :roles, :slug, unique: true

    create_table :permissions do |t|
      t.string :name, null: false   # ej: products.view
      t.string :label, null: false
      t.string :module_key, null: false
      t.timestamps
    end
    add_index :permissions, :name, unique: true

    create_table :permissions_roles, id: false do |t|
      t.references :role, null: false, foreign_key: true
      t.references :permission, null: false, foreign_key: true
    end
    add_index :permissions_roles, %i[role_id permission_id], unique: true
  end
end
