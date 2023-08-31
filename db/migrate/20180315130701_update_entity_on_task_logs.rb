class UpdateEntityOnTaskLogs < ActiveRecord::Migration[4.2]
  def change
    add_reference :project_task_logs, :working_entity, index: true
  end
end
