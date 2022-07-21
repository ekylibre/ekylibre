class AddCreatorAndUpdatorToTechnicalItinerary < ActiveRecord::Migration[4.2]
  def change
    unless column_exists?(:technical_itineraries, :creator_id)
      add_column :technical_itineraries, :creator_id, :integer
    end
    unless column_exists?(:technical_itineraries, :updater_id)
      add_column :technical_itineraries, :updater_id, :integer
    end
  end
end
