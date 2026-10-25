class CreateHveNitrogenExportCoefficients < ActiveRecord::Migration[5.2]
  def change
    create_table :hve_nitrogen_export_coefficients do |t|
      t.string  :crop_reference, null: false  # Onoma key (e.g. 'wheat', 'corn_silage')
      t.string  :organ, null: false           # grain | straw | tuber | root | fodder | …
      t.decimal :ms_pct,        precision: 5, scale: 2  # dry matter percentage
      t.decimal :n_kg_per_t,    precision: 6, scale: 3, null: false
      t.string  :unit, default: 'fresh_matter' # fresh_matter | dry_matter
      t.string  :source                        # Comifer 2013 etc.
      t.timestamps null: false
    end
    add_index :hve_nitrogen_export_coefficients, %i[crop_reference organ], unique: true, name: :index_hve_n_exports_on_crop_organ
  end
end
