class AddAnalyticAccountancy < ActiveRecord::Migration
  def change
    add_reference :purchase_items, :campaign, index: true
    add_reference :purchase_items, :activity, index: true
    add_reference :sale_items, :campaign, index: true
    add_reference :sale_items, :activity, index: true
    add_reference :journal_entry_items, :campaign, index: true
    add_reference :journal_entry_items, :activity, index: true
  end
end
