class AddDataToIntegrations < ActiveRecord::Migration
  def change
    add_column :integrations, :data, :jsonb
  end
end
