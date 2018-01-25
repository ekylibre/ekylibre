# This migration comes from planning_engine (originally 20180124130951)
class AddIsDuplicateToTechnicalItineraryInterventionTemplate < ActiveRecord::Migration
  def change
    add_column :technical_itinerary_intervention_templates, :is_duplicate, :boolean, default: false
  end
end
