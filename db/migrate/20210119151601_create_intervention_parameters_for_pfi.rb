class CreateInterventionParametersForPfi < ActiveRecord::Migration[4.2]
  def change
    create_table :pfi_intervention_parameters do |t|
      t.decimal :pfi_value, precision: 19, scale: 4, default: 1.0, null: false
      t.string :nature, null: false
      t.string :segment_code
      t.text :signature
      t.jsonb :response, null: false
      t.references :campaign, index: { name: :pfi_intervention_parameters_campaign_id }
      t.references :input, index: { name: :pfi_intervention_parameters_input_id }
      t.references :target, index: { name: :pfi_intervention_parameters_target_id }
      t.timestamps
    end
    add_foreign_key :pfi_intervention_parameters, :intervention_parameters, column: :input_id
    add_foreign_key :pfi_intervention_parameters, :intervention_parameters, column: :target_id
    add_foreign_key :pfi_intervention_parameters, :campaigns, column: :campaign_id
  end
end
