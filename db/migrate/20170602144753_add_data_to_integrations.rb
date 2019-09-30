class AddDataToIntegrations < ActiveRecord::Migration[4.2]
  def change
    add_column :integrations, :data, :jsonb
  end
end
