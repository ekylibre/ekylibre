class AddProviderToObservation < ActiveRecord::Migration[5.0]
  def change
    add_column :yield_observations, :provider, :jsonb, default: {}
  end
end
