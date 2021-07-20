class AddInterventionToRide < ActiveRecord::Migration[5.0]
  def change
    add_reference :rides, :intervention, foreign_key: true
  end
end
