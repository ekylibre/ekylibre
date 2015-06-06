class AddTasks < ActiveRecord::Migration
  def change

    create_table :tasks do |t|
      t.string     :name,        null: false
      t.string     :state,       null: false
      t.references :entity,      null: false, index: true
      t.references :executor,                 index: true
      t.references :sale_opportunity,         index: true
      t.text       :description
      t.datetime   :due_at
      t.stamps
    end

  end
end
