class UpdateTasks < ActiveRecord::Migration[4.2]
  def change
    add_column :project_tasks, :work_number, :string
    add_column :projects, :work_number, :string
    add_column :project_task_logs, :travel_expenses, :boolean, null: false, default: false
    add_column :project_task_logs, :travel_expense_details, :string
  end
end
