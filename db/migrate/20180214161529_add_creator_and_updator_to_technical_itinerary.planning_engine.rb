# This migration comes from planning_engine (originally 20180214161453)
class AddCreatorAndUpdatorToTechnicalItinerary < ActiveRecord::Migration
  def change
    add_column :technical_itineraries, :creator_id, :integer
    add_column :technical_itineraries, :updater_id, :integer
  end
end
