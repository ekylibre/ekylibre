class AddAnalyticAccountancy < ActiveRecord::Migration
  def change
    add_reference :purchase_items, :activity_budget, index: true
    add_reference :sale_items, :activity_budget, index: true
    add_reference :journal_entry_items, :activity_budget, index: true
  end
end
