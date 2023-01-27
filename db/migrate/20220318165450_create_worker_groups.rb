class CreateWorkerGroups < ActiveRecord::Migration[5.0]
  def change
    if table_exists? :worker_groups
      drop_table :worker_groups, cascade: true
    end
    create_table :worker_groups do |t|
      t.string :name, null: false
      t.string :work_number
      t.boolean :active, default: true, null: false
      t.string :usage
      t.stamps
    end
    if table_exists? :worker_group_items
      remove_reference :products, :worker_group_item
      drop_table :worker_group_items, cascade: true
    end
    create_table :worker_group_items do |t|
      t.references :worker, index: true
      t.references :worker_group, index: true
      t.timestamps
    end
    if table_exists? :worker_group_labellings
      drop_table :worker_group_labellings, cascade: true
    end
    create_table :worker_group_labellings do |t|
      t.references :worker_group, index: true, foreign_key: true
      t.references :label, index: true, foreign_key: true
      t.timestamps null: false
    end
    add_reference :products, :worker_group_item, foreign_key: true
  end
end
