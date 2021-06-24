class AddDisableAccountancyOptionForInventories < ActiveRecord::Migration[4.2]
  def change
    add_column :inventories, :disable_accountancy, :boolean, default: false
  end
end
