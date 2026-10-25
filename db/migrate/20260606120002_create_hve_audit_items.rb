class CreateHveAuditItems < ActiveRecord::Migration[5.2]
  def change
    create_table :hve_audit_items do |t|
      t.references :hve_audit, null: false, foreign_key: true, index: true
      t.string  :code,  null: false  # e.g. '4.1', '5.3.herbicide'
      t.string  :theme, null: false  # biodiversity | phytosanitary | fertilisation | irrigation
      t.decimal :value_raw,    precision: 12, scale: 4
      t.decimal :value_manual, precision: 12, scale: 4
      t.decimal :value_used,   precision: 12, scale: 4
      t.decimal :points,     precision: 6, scale: 2
      t.decimal :points_max, precision: 6, scale: 2
      t.boolean :auto_computed, default: true, null: false
      t.text    :notes
      t.jsonb   :evidence, default: {}, null: false
      t.timestamps null: false
    end
    add_index :hve_audit_items, %i[hve_audit_id code], unique: true
    add_index :hve_audit_items, :theme
  end
end
