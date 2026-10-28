class RenameDemoCompany < ActiveRecord::Migration[7.1]
  def up
    execute "UPDATE settings SET value = 'Don Vito Licorería' WHERE `key` = 'company_name' AND value = 'Licorería Demo'"
  end

  def down; end
end
