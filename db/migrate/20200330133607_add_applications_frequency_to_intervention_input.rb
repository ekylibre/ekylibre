class AddApplicationsFrequencyToInterventionInput < ActiveRecord::Migration[4.2]
  def change
    add_column :intervention_parameters, :applications_frequency, :interval, default: nil
  end
end
