class ChangeDefaultImputationRatioToInterventionTargets < ActiveRecord::Migration[4.2]
  def up
    change_column_default :intervention_parameters, :imputation_ratio, 1
    change_column_null :intervention_parameters, :imputation_ratio, false, 1
  end

  def down
    change_column_default :intervention_parameters, :imputation_ratio, nil
    change_column_null :intervention_parameters, :imputation_ratio, true
  end
end
