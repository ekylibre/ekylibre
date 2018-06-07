# This migration comes from planning_engine (originally 20180115135241)
class CreateTechnicalItineraries < ActiveRecord::Migration
  def change
    create_table :technical_itineraries do |t|
      t.string :name
      t.references :campaign, index: true, foreign_key: true
      t.references :activity, index: true, foreign_key: true
      t.string :description
      t.timestamps null: false
    end
  end
end
