class AddBudgets < ActiveRecord::Migration
  def change

    create_table :budget_items do |t|
      t.references :budget,             null: false, index: true
      t.references :production_support,              index: true
      t.decimal    :quantity,           null: false, default: 0.0, precision: 19, scale: 4
      t.decimal    :global_amount,      null: false, default: 0.0, precision: 19, scale: 4
      t.string     :currency
      t.stamps
    end

    create_table :budgets do |t|
      t.references :variant,         index: true
      t.references :production,      index: true
      t.string     :name
      t.string     :direction
      t.decimal    :global_amount,   default: 0.0, precision: 19, scale: 4
      t.decimal    :unit_amount,     default: 0.0, precision: 19, scale: 4
      t.decimal    :global_quantity, default: 0.0, precision: 19, scale: 4
      t.string     :working_indicator
      t.string     :working_unit
      t.string     :computation_method
      t.boolean    :homogeneous_values, default: false
      t.string     :currency
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
