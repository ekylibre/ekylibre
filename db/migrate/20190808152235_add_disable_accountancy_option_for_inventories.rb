class AddDisableAccountancyOptionForInventories < ActiveRecord::Migration
  def change
    add_column :inventories, :disable_accountancy, :boolean, default: false
  end
end
