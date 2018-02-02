# This migration comes from planning_engine (originally 20180130090052)
class AddParentIdToTechnicalItineraryInterventionTemplate < ActiveRecord::Migration
  def change
    remove_column :technical_itinerary_intervention_templates, :is_duplicate, :boolean, default: false
    add_column :technical_itinerary_intervention_templates, :reference_hash, :string
    add_column :technical_itinerary_intervention_templates, :parent_hash, :string
  end
end
