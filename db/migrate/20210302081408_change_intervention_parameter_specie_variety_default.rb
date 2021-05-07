class ChangeInterventionParameterSpecieVarietyDefault < ActiveRecord::Migration[5.0]
  def up
    change_column :intervention_parameters, :specie_variety, :jsonb, using: "(specie_variety#>> '{}')::jsonb", default: {}
  end

  def down
    change_column :intervention_parameters, :specie_variety, :jsonb, default: '{}'
  end
end
