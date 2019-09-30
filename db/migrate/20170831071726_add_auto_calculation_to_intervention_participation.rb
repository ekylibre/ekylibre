class AddAutoCalculationToInterventionParticipation < ActiveRecord::Migration[4.2]
  def change
    add_column :interventions, :auto_calculate_working_periods, :boolean, default: false
  end
end
