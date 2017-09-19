class AddInterventionToParcels < ActiveRecord::Migration
  def change
    add_reference :parcels, :intervention, index: true, foreign_key: true
  end
end
