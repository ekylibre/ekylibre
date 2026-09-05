class CreateHveAudits < ActiveRecord::Migration[5.2]
  def change
    create_table :hve_audits do |t|
      t.references :campaign, null: false, foreign_key: true, index: true
      t.string  :referentiel_version, null: false, default: 'V4.4'
      t.string  :filiere
      t.string  :status, null: false, default: 'draft'
      t.date    :started_on
      t.date    :closed_on
      t.boolean :uses_cmr1_without_derogation, default: false, null: false
      t.decimal :score_biodiversity,  precision: 6, scale: 2
      t.decimal :score_phytosanitary, precision: 6, scale: 2
      t.decimal :score_fertilisation, precision: 6, scale: 2
      t.decimal :score_irrigation,    precision: 6, scale: 2
      t.string  :verdict
      t.jsonb   :metadata, default: {}, null: false
      t.references :creator, foreign_key: { to_table: :users }, index: true
      t.references :updater, foreign_key: { to_table: :users }, index: true
      t.integer :lock_version, default: 0, null: false
      t.timestamps null: false
    end
    add_index :hve_audits, %i[campaign_id referentiel_version], unique: true, name: :index_hve_audits_on_campaign_referentiel
  end
end
