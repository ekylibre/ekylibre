class AddProjects < ActiveRecord::Migration[4.2]
  def change
    create_table :projects do |t|
      t.references :activity, index: true, foreign_key: true
      t.string :nature, null: false
      t.string :name, null: false
      t.references :responsible, index: true
      t.references :sale_contract, index: true
      t.date :started_on
      t.date :stopped_on
      t.text :comment
      t.boolean :closed, null: false, default: false
      t.stamps
    end
    add_foreign_key :projects, :users, column: :responsible_id

    create_table :project_members do |t|
      t.references :project, null: false, index: true, foreign_key: true
      t.references :user, null: false, index: true, foreign_key: true
      t.string :role
      t.stamps
    end

    create_table :project_tasks do |t|
      t.references :project, null: false, index: true, foreign_key: true
      t.references :responsible, index: true
      t.references :sale_contract_item, index: true
      t.string :billing_method
      t.date :started_on
      t.date :stopped_on
      t.decimal :forecast_duration, precision: 9, scale: 2
      t.string :name, null: false
      t.text :comment
      t.stamps
    end
    add_foreign_key :project_tasks, :users, column: :responsible_id

    create_table :project_task_logs do |t|
      t.references :project_task, null: false, index: true, foreign_key: true
      t.references :worker, index: true
      t.date :worked_on, null: false
      t.decimal :duration, null: false, precision: 9, scale: 2
      t.references :sale_item, index: true
      t.datetime :started_at
      t.text :comment
      t.stamps
    end
    add_foreign_key :project_task_logs, :users, column: :worker_id
  end
end
