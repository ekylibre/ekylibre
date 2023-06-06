class CreateYieldObservations < ActiveRecord::Migration[5.0]
  def change
    unless table_exists?(:yield_observations)
      create_table :yield_observations do |t|
        t.datetime :observed_at
        t.references :activity, null: false, index: true
        t.references :vegetative_stage
        t.st_point :geolocation, srid: 4326
        t.text :description
        t.string :number
        t.stamps
      end
    end

    unless table_exists?(:products_yield_observations)
      create_table :products_yield_observations do |t|
        t.references :yield_observation, null: false, index: true
        t.references :product, null: false, index: true
        t.geometry :working_zone, srid: 4326
      end
    end

    unless table_exists?(:issues_yield_observations)
      create_table :issues_yield_observations do |t|
        t.references :yield_observation, null: false, index: true
        t.references :issue, null: false, index: true
      end
    end
    unless table_exists?(:vegetative_stages)
      create_table :vegetative_stages do |t|
        t.string :bbch_number, null: false
        t.string :label, null: false
        t.string :variety, null: false
        t.stamps
      end
    end

    unless table_exists?(:issue_natures)
      create_table :issue_natures do |t|
        t.string :category, null: false
        t.string :label, null: false
        t.string :nature, null: false
      end

      add_column :issues, :issue_nature_id, :integer, index: true
      add_foreign_key :issues, :issue_natures, column: :issue_nature_id
    end
  end
end
