class CreateWorkerGroups < ActiveRecord::Migration[5.0]
  def change
    create_table :worker_groups do |t|
      t.string :name, null: false
      t.string :work_number
      t.boolean :active, default: true, null: false
      t.string :usage
      t.stamps
    end
    create_table :worker_group_items do |t|
      t.references :worker, index: true
      t.references :worker_group, index: true
      t.timestamps
    end
    create_table :worker_group_labellings do |t|
      t.references :worker_group, index: true, foreign_key: true
      t.references :label, index: true, foreign_key: true
      t.timestamps null: false
    end
    add_reference :products, :worker_group_item, foreign_key: true
  end
end
