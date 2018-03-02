# This migration comes from planning_engine (originally 20180222160026)
class AddPlannificationColumnsToActivityProduction < ActiveRecord::Migration
  def change
    add_reference :activity_productions, :technical_itinerary, index: true, foreign_key: true
    add_column :activity_productions, :predicated_sowing_date, :date
    add_column :activity_productions, :batch_planting, :boolean
    add_column :activity_productions, :number_of_batch, :integer
    add_column :activity_productions, :sowing_interval, :integer
  end
end
