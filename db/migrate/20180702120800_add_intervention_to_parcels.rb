class AddInterventionToParcels < ActiveRecord::Migration
  def change
    unless column_exists? :parcels, :intervention_id
      add_reference :parcels, :intervention, index: true, foreign_key: true
    end
  end
end
