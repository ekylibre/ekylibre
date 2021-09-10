class AddIsDuplicateToTechnicalItineraryInterventionTemplate < ActiveRecord::Migration
  def change
    unless column_exists?(:technical_itinerary_intervention_templates, :is_duplicate)
      add_column :technical_itinerary_intervention_templates, :is_duplicate, :boolean, default: false
    end
  end
end
