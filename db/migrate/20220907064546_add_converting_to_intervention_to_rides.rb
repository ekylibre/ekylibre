class AddConvertingToInterventionToRides < ActiveRecord::Migration[5.1]
  def change
    add_column :rides, :converting_to_intervention, :boolean, default: false, null: false
  end
end
