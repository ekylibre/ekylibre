class ChangeBookkeepOnFixedAssets < ActiveRecord::Migration
  def change
    add_column :fixed_assets, :state, :string
    add_column :fixed_assets, :accounted_at, :datetime
    add_reference :fixed_assets, :journal_entry, index: true
    add_reference :fixed_assets, :asset_account, index: true
    reversible do |r|
      r.up do
        execute "UPDATE fixed_assets SET state = 'draft'"
      end
    end
  end
end
