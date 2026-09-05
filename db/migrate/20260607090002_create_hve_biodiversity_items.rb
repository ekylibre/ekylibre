class CreateHveBiodiversityItems < ActiveRecord::Migration[5.2]
  def change
    create_table :hve_biodiversity_items do |t|
      t.references :hve_audit, null: false, foreign_key: true, index: true
      t.string  :iae_family, null: false
      t.string  :iae_type,   null: false
      t.decimal :surface_or_length, precision: 12, scale: 3, null: false
      t.string  :unit, null: false  # 'ha' | 'm'
      t.decimal :coefficient,       precision: 6,  scale: 3
      t.decimal :equivalent_iae_ha, precision: 12, scale: 4
      t.string  :location_notes
      t.timestamps null: false
    end
    add_index :hve_biodiversity_items, %i[hve_audit_id iae_family]
  end
end
