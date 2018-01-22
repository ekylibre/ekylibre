# This migration comes from planning_engine (originally 20180116133217)
class CreateTechnicalItineraryInterventionTemplates < ActiveRecord::Migration
  def change
    create_table :technical_itinerary_intervention_templates do |t|
      t.references :technical_itinerary, index: { name: :template_itinerary_id }, foreign_key: true
      t.references :intervention_template, index: { name: :itinerary_template_id }, foreign_key: true
      t.integer :position
      t.integer :day_between_intervention
      t.integer :duration
      t.boolean :dont_divide_duration, default: false
      t.timestamps null: false
    end
  end
end
