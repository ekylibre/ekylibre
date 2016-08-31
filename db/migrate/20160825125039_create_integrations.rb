class CreateIntegrations < ActiveRecord::Migration
  def change
    create_table :integrations do |t|
      t.string :nature

      t.jsonb :parameters

      t.stamps
    end

    add_index :integrations, :nature, unique: true
  end
end
