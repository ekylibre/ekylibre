class AddProviderOnProductions < ActiveRecord::Migration[5.0]
  def change
    add_column :activity_productions, :provider, :jsonb, default: {}
  end
end
