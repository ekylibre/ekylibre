class ChangeTimeLogs < ActiveRecord::Migration[5.2]
  def up
    add_reference :worker_time_logs, :project_task, index: true
    add_column :worker_time_logs, :travel_expense, :boolean, null: false, default: false
    add_column :worker_time_logs, :travel_expense_details, :text
  end

  def down
    remove_table :project_task_logs
  end
end
