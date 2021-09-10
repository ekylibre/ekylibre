class AddParentIdToTechnicalItineraryInterventionTemplate < ActiveRecord::Migration
  def change
    remove_column :technical_itinerary_intervention_templates, :is_duplicate, :boolean, default: false
    unless column_exists?(:technical_itinerary_intervention_templates, :reference_hash)
      add_column :technical_itinerary_intervention_templates, :reference_hash, :string
    end
    unless column_exists?(:technical_itinerary_intervention_templates, :parent_hash)
      add_column :technical_itinerary_intervention_templates, :parent_hash, :string
    end
  end
end
