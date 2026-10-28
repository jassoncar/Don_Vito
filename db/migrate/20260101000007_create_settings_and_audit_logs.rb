class CreateSettingsAndAuditLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :settings do |t|
      t.string :key, null: false
      t.text :value
      t.timestamps
    end
    add_index :settings, :key, unique: true

    create_table :audit_logs do |t|
      t.references :user, foreign_key: true
      t.string :action, null: false
      t.string :auditable_type
      t.bigint :auditable_id
      t.string :description, null: false
      t.json :old_values
      t.json :new_values
      t.string :ip_address, limit: 45
      t.timestamps
    end
    add_index :audit_logs, %i[auditable_type auditable_id]
  end
end
