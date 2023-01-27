class RemoveStateFromRides < ActiveRecord::Migration[5.1]
  def change
    remove_column :rides, :state, :string
  end
end
