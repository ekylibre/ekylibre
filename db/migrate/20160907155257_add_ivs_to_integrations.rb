class AddIvsToIntegrations < ActiveRecord::Migration
  def change
    add_column :integrations, :initialization_vectors, :jsonb
    rename_column :integrations, :parameters, :ciphered_parameters
  end
end
