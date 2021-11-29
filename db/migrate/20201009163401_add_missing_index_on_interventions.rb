class AddMissingIndexOnInterventions < ActiveRecord::Migration[4.2]
  def change
    add_index :activity_productions, :support_nature
    add_index :intervention_working_periods, :intervention_participation_id, name: 'index_intervention_working_periods_on_int_part_id'
    add_index :intervention_working_periods, [:intervention_id, :intervention_participation_id], name: 'index_intervention_working_periods_on_int_and_int_part_ids'
    add_index :intervention_participations, [:product_id, :intervention_id], name: 'index_intervention_participations_on_pro_and_int_ids'
    add_index :intervention_parameters, [:product_id, :intervention_id], name: 'index_intervention_parameters_on_pro_and_int_ids'
    add_index :intervention_parameters, [:product_id, :reference_name, :type], name: 'index_intervention_parameters_on_pro_and_ref_and_type'
    add_index :intervention_parameters, [:intervention_id, :type], name: 'index_intervention_parameters_on_int_and_type'
    add_index :intervention_parameters, [:product_id, :type], name: 'index_intervention_parameters_on_pro_and_type'
  end
end
