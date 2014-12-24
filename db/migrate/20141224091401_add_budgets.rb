class AddBudgets < ActiveRecord::Migration
  def change

    create_table :budget_items do |t|
      t.references :budget,             null: false, index: true
      t.references :production_support, null: false, index: true
      t.decimal    :quantity,           null: false, default: 0.0, precision: 19, scale: 4
      t.decimal    :global_amount,      null: false, default: 0.0, precision: 19, scale: 4
      t.string     :currency,           null: false
      t.stamps
    end

    create_table :budgets do |t|
      t.references :variant,         null: false, index: true
      t.references :production,      null: false, index: true
      t.string     :name,            null: false
      t.string     :direction,       null: false
      t.decimal    :global_amount,   null: false, default: 0.0, precision: 19, scale: 4
      t.decimal    :unit_amount,     null: false, default: 0.0, precision: 19, scale: 4
      t.decimal    :global_quantity, null: false, default: 0.0, precision: 19, scale: 4
      t.string     :working_indicator
      t.string     :working_unit
      t.string     :computation_method
      t.boolean    :homogeneous_values, null: false, default: false
      t.string     :currency,        null: false
      t.stamps
      t.index      :name
    end

    change_table :productions do |t|
      t.string    :working_indicator
      t.string    :working_unit
      t.integer   :support_variant_id
      t.boolean   :homogeneous_expenses, default: false
      t.boolean   :homogeneous_revenues, default: false
    end

  end
end
