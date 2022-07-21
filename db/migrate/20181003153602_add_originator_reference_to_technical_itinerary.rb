class AddOriginatorReferenceToTechnicalItinerary < ActiveRecord::Migration[4.2]
  def change
    unless column_exists?(:technical_itineraries, :originator_id)
      add_column :technical_itineraries, :originator_id, :integer, null: true
    end
  end
end
