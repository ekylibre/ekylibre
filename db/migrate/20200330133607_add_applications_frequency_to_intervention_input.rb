class AddApplicationsFrequencyToInterventionInput < ActiveRecord::Migration
  def change
    add_column :intervention_parameters, :applications_frequency, :interval, default: nil
  end
end
