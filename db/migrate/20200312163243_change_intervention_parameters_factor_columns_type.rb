class ChangeInterventionParametersFactorColumnsType < ActiveRecord::Migration
  def change
    database = Rails.configuration.database_configuration[Rails.env]['database']
    execute "ALTER DATABASE #{database} SET IntervalStyle = 'iso_8601'"
    change_column :intervention_parameters, :allowed_entry_factor, "interval USING (allowed_entry_factor || 'hours')::interval"
    change_column :intervention_parameters, :allowed_harvest_factor, "interval USING (allowed_harvest_factor || 'days')::interval"
  end
end
