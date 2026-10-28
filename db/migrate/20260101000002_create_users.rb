class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.references :role, foreign_key: true
      t.boolean :is_active, null: false, default: true
      t.timestamps
    end
    add_index :users, :email, unique: true
  end
end
