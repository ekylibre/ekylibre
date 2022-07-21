class CreateTechnicalItineraries < ActiveRecord::Migration[4.2]
  def change
    unless data_source_exists?(:technical_itineraries)
      create_table :technical_itineraries do |t|
        t.string :name
        t.references :campaign, index: true, foreign_key: true
        t.references :activity, index: true, foreign_key: true
        t.string :description
        t.timestamps null: false
      end
    end
  end
end
