class AddApplicationModeToInterventionParameters < ActiveRecord::Migration[5.2]
  def change
    add_column :intervention_parameters, :application_mode, :string
  end
end
