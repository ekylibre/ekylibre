class AddDontDivideToTechnicalItineraryInterventionTemplate < ActiveRecord::Migration
  def change
    unless column_exists?(:technical_itinerary_intervention_templates, :dont_divide_duration)
      add_column :technical_itinerary_intervention_templates, :dont_divide_duration, :boolean, default: false
    end
  end
end
