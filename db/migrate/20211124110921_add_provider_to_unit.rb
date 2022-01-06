class AddProviderToUnit < ActiveRecord::Migration[5.0]
  def change
    add_column :units, :provider, :jsonb
  end
end
