class CreateHveCmrProducts < ActiveRecord::Migration[5.2]
  def change
    create_table :hve_cmr_products do |t|
      t.string  :amm_code,    null: false
      t.string  :product_name
      t.string  :cmr_class,   null: false  # 'CMR1' | 'CMR2'
      t.string  :status               # AUTORISE | RETIRE
      t.date    :first_authorisation_on
      t.date    :withdrawal_on
      t.integer :snapshot_year, null: false  # e.g. 2025
      t.string  :type_label    # AMM | Second Nom | PCP
      t.text    :active_substances
      t.text    :functions
      t.timestamps null: false
    end
    add_index :hve_cmr_products, %i[amm_code snapshot_year], unique: true, name: :index_hve_cmr_on_amm_and_year
    add_index :hve_cmr_products, %i[snapshot_year cmr_class]
  end
end
