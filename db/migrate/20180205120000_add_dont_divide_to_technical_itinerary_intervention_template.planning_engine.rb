# This migration comes from planning_engine (originally 20180124113015)
class AddDontDivideToTechnicalItineraryInterventionTemplate < ActiveRecord::Migration
  def change
    add_column :technical_itinerary_intervention_templates, :dont_divide_duration, :boolean, default: false
  end
end
