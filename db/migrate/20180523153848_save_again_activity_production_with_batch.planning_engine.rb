# This migration comes from planning_engine (originally 20180523153734)
class SaveAgainActivityProductionWithBatch < ActiveRecord::Migration
  def change
    ActivityProduction.where(batch_planting: true).each do |activity_production|
      activity_production.save
    end
  end
end
