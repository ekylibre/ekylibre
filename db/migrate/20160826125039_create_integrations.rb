class CreateIntegrations < ActiveRecord::Migration
  def change
    create_table :integrations do |t|
      t.string :nature, null: false
      t.jsonb :initialization_vectors
      t.jsonb :ciphered_parameters
      t.stamps
      t.index :nature, unique: true
    end
  end
end
