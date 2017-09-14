class AddAutoCalculationToInterventionParticipation < ActiveRecord::Migration
  def change
    add_column :interventions, :auto_calculate_working_periods, :boolean, default: false
  end
end
