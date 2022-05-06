class AddNameToInterventionParameterSetting < ActiveRecord::Migration[5.0]
  def change
    add_column :intervention_parameter_settings, :name, :string, null: false, default: 'Default name'
  end
end
