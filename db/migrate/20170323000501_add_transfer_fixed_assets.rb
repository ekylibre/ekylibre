class AddTransferFixedAssets < ActiveRecord::Migration
  def change
    add_column :fixed_assets, :sold_on, :date
    add_column :fixed_assets, :scrapped_on, :date
    add_reference :fixed_assets, :sold_journal_entry, index: true
    add_reference :fixed_assets, :scrapped_journal_entry, index: true
  end
end
