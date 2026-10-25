class AddBbchStageToInterventionParameters < ActiveRecord::Migration[5.2]
  def change
    add_column :intervention_parameters, :phenological_bbch_stage, :integer
  end
end
