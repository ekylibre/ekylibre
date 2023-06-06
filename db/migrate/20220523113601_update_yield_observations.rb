class UpdateYieldObservations < ActiveRecord::Migration[5.0]
  def change
    add_column :products_yield_observations, :vegetative_stage_id, :integer, index: true
    add_column :issues, :products_yield_observation_id, :integer, index: true
  end
end
