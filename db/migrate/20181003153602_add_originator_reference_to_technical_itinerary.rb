class AddOriginatorReferenceToTechnicalItinerary < ActiveRecord::Migration
  def change
    unless column_exists?(:technical_itineraries, :originator_id)
      add_column :technical_itineraries, :originator_id, :integer, null: true
    end
  end
end
