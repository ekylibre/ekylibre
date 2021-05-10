class AddProviderToProducts < ActiveRecord::Migration[4.2]
  def change
    add_column :products, :provider, :jsonb, default: {}
  end
end
