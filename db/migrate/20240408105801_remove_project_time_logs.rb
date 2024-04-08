class RemoveProjectTimeLogs < ActiveRecord::Migration[5.2]
  def up
    drop_table :project_task_logs, if_exists: true
  end
end


