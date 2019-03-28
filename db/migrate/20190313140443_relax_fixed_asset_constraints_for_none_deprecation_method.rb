class RelaxFixedAssetConstraintsForNoneDeprecationMethod < ActiveRecord::Migration
  def change
    reversible do |r|
      r.up do
        change_column :fixed_assets, :stopped_on, :date, null: true
        change_column :fixed_assets, :allocation_account_id, :integer, null: true
      end

      r.down do
        change_column :fixed_assets, :stopped_on, :date, null: false
        change_column :fixed_assets, :allocation_account_id, :integer, null: false
      end
    end
  end
end
