class CreateAnalyticOptionForWorkerContract < ActiveRecord::Migration[5.0]
  def change
    add_column :worker_contracts, :distribution_key, :string
    create_table :worker_contract_distributions do |t|
      t.references :worker_contract, null: false, index: true
      t.decimal :affectation_percentage, precision: 19, scale: 4, null: false
      t.references :main_activity, null: false, index: true
      t.stamps
    end
  end
end
