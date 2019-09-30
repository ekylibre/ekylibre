class AddInspectionForecastHarvestWeek < ActiveRecord::Migration[4.2]
  def change
    add_column :inspections, :forecast_harvest_week, :integer
  end
end
