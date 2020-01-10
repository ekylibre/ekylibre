class AddInspectionForecastHarvestWeek < ActiveRecord::Migration
  def change
    add_column :inspections, :forecast_harvest_week, :integer
  end
end
