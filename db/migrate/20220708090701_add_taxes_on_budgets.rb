class AddTaxesOnBudgets < ActiveRecord::Migration[5.0]
  def up
    add_reference :activity_budget_items, :tax, index: true, foreign_key: { to_table: :taxes}
    rename_column :activity_budget_items, :amount, :pretax_amount
    add_column :activity_budget_items, :amount, :decimal, precision: 19, scale: 4
    add_column :activity_budget_items, :global_pretax_amount, :decimal, precision: 19, scale: 4

    execute <<~SQL
      UPDATE activity_budget_items
      SET tax_id = (SELECT MIN(id) FROM taxes WHERE amount = 10.0),
      amount = (pretax_amount * 1.10)
      WHERE nature = 'dynamic' AND origin = 'itk'
    SQL

    execute <<~SQL
      UPDATE activity_budget_items
      SET tax_id = (SELECT MIN(id) FROM taxes WHERE amount = 20.0),
      amount = (pretax_amount * 1.20)
      WHERE nature = 'static' AND origin = 'itk'
    SQL

    execute <<~SQL
      UPDATE activity_budget_items
      SET tax_id = (SELECT MIN(id) FROM taxes WHERE amount = 0.0)
      WHERE tax_id IS NULL
    SQL
  end

  def down
    remove_reference :activity_budget_items, :tax, index: true, foreign_key: true
    remove_column :activity_budget_items, :pretax_amount
    remove_column :activity_budget_items, :global_pretax_amount

    execute <<~SQL
      UPDATE activity_budget_items
      SET amount = (amount / 1.10)
      WHERE nature = 'dynamic' AND origin = 'itk'
    SQL

    execute <<~SQL
      UPDATE activity_budget_items
      SET amount = (amount / 1.20)
      WHERE nature = 'static' AND origin = 'itk'
    SQL

  end
end
