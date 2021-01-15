class AddAnalyticAccountancy < ActiveRecord::Migration[4.2]
  def change
    add_reference :purchase_items, :activity_budget, index: true
    add_reference :sale_items, :activity_budget, index: true
    add_reference :journal_entry_items, :activity_budget, index: true
  end
end
