class AddPlannificationColumnsToActivityProduction < ActiveRecord::Migration
  def change
    unless column_exists?(:activity_productions, :technical_itinerary_id)
      add_reference :activity_productions, :technical_itinerary, index: true, foreign_key: true
    end
    unless column_exists?(:activity_productions, :predicated_sowing_date)
      add_column :activity_productions, :predicated_sowing_date, :date
    end
    unless column_exists?(:activity_productions, :batch_planting)
      add_column :activity_productions, :batch_planting, :boolean
    end
    unless column_exists?(:activity_productions, :number_of_batch)
      add_column :activity_productions, :number_of_batch, :integer
    end
    unless column_exists?(:activity_productions, :sowing_interval)
      add_column :activity_productions, :sowing_interval, :integer
    end
  end
end
