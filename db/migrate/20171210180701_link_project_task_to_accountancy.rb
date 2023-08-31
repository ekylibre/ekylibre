class LinkProjectTaskToAccountancy < ActiveRecord::Migration[4.2]
  def change
    add_reference :journal_entry_items, :project_task, index: true
    add_reference :sale_items, :project_task, index: true
    add_reference :purchase_items, :project_task, index: true
  end
end
