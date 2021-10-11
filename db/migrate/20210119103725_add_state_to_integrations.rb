class AddStateToIntegrations < ActiveRecord::Migration
  def change
    add_column :integrations, :state, :string

    execute <<-SQL
      UPDATE integrations SET state = 'undone';
    SQL
  end
end
