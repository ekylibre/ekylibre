class AddSpecieVarietyToInterventionParameters < ActiveRecord::Migration[4.2]
  def change
    add_column :intervention_parameters, :specie_variety, :jsonb, default: '{}'
  end
end
