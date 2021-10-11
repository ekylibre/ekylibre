class UpdateActivityForItks < ActiveRecord::Migration
  def change
    add_column :activity_tactics, :default, :boolean, default: false
    add_column :activity_tactics, :technical_workflow_id, :string, index: true
    add_column :activity_tactics, :technical_workflow_sequence_id, :string, index: true
    add_reference :technical_itineraries, :activity_tactic, index: true
    add_column :intervention_templates, :technical_workflow_procedure_id, :string, index: true
    add_column :intervention_templates, :intervention_model_id, :string, index: true
    add_column :intervention_template_product_parameters, :intervention_model_item_id, :string, index: true
    add_column :intervention_template_product_parameters, :technical_workflow_procedure_item_id, :string, index: true
    add_column :technical_itinerary_intervention_templates, :day_since_start, :decimal, precision: 19, scale: 4
  end
end
