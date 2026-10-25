class CreateHveScoringTables < ActiveRecord::Migration[5.2]
  def change
    create_table :hve_scoring_tables do |t|
      t.string  :filiere, null: false       # gc | viticulture | arboriculture | horticulture
      t.string  :region                     # NUTS-2 / bassin viticole / region fruitière
      t.string  :ift_type, null: false      # herbicide | hors_herbicide
      t.decimal :pc, precision: 6, scale: 3 # plancher (20e perc.)
      t.decimal :pf, precision: 6, scale: 3 # plafond (70e perc.)
      t.string  :referentiel_version, default: 'V4.4'
      t.timestamps null: false
    end
    add_index :hve_scoring_tables, %i[filiere region ift_type], unique: true, name: :index_hve_scoring_unique
  end
end
