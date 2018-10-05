class UpdateActivityProductionToHaveTheGoodPopulation < ActiveRecord::Migration
  def change
    unvalid_activity_productions = []
    ActivityProduction.find_each do |activity_production|
      begin
        activity_production.save if activity_production.plant_farming?
      rescue
        unvalid_activity_productions << activity_production.id
      end
    end
    puts unvalid_activity_productions
  end
end
