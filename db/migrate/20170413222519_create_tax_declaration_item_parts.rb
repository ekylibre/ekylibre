class CreateTaxDeclarationItemParts < ActiveRecord::Migration
  def change
    create_table :tax_declaration_item_parts do |t|
      t.references :tax_declaration_item, index: true, null: false, foreign_key: true
      t.references :journal_entry_item, index: true, null: false, foreign_key: true
      t.references :account, index: true, null: false, foreign_key: true
      t.decimal :tax_amount, precision: 19, scale: 4, null: false
      t.decimal :pretax_amount, precision: 19, scale: 4, null: false
      t.decimal :total_tax_amount, precision: 19, scale: 4, null: false
      t.decimal :total_pretax_amount, precision: 19, scale: 4, null: false
      t.string :direction, null: false
      t.stamps
      t.index :direction # collected, deductible, fixed_asset_deductible, intracommunity_payable
    end

    reversible do |r|
      r.up do
        execute create_parts_on_previous_declarations_sql
      end
      r.down do
      end
    end
  end

  def create_parts_on_previous_declarations_sql
    <<-SQL
      INSERT INTO tax_declaration_item_parts (
        tax_declaration_item_id,
        journal_entry_item_id,
        account_id,
        tax_amount,
        total_tax_amount,
        pretax_amount,
        total_pretax_amount,
        direction,
        created_at,
        updated_at
      )
      #{select_parts_attributes_on_previous_declarations_sql}
    SQL
  end

  def select_parts_attributes_on_previous_declarations_sql
    <<-SQL
    SELECT
      journal_entry_items.tax_declaration_item_id AS tax_declaration_item_id,
      journal_entry_items.id AS journal_entry_item_id,
      accounts.id AS account_id,
      (CASE
        WHEN accounts.id = taxes.collect_account_id THEN (journal_entry_items.credit - journal_entry_items.debit)
        ELSE (journal_entry_items.debit - journal_entry_items.credit)
      END) AS tax_amount,
      (CASE
        WHEN accounts.id = taxes.collect_account_id THEN (journal_entry_items.credit - journal_entry_items.debit)
        ELSE (journal_entry_items.debit - journal_entry_items.credit)
      END) AS total_tax_amount,
      journal_entry_items.pretax_amount AS pretax_amount,
      journal_entry_items.pretax_amount AS total_pretax_amount,
      (CASE
        WHEN accounts.id = taxes.deduction_account_id THEN 'deductible'
        WHEN accounts.id = taxes.collect_account_id THEN 'collected'
        WHEN accounts.id = taxes.fixed_asset_deduction_account_id THEN 'fixed_asset_deductible'
        WHEN accounts.id = taxes.intracommunity_payable_account_id THEN 'intracommunity_payable'
      END) AS direction,
      CURRENT_TIMESTAMP AS created_at,
      CURRENT_TIMESTAMP AS updated_at
    FROM
      taxes
    INNER JOIN accounts ON (
      accounts.id = taxes.deduction_account_id
      OR
      accounts.id = taxes.fixed_asset_deduction_account_id
      OR
      accounts.id = taxes.collect_account_id
      OR
      accounts.id = taxes.intracommunity_payable_account_id
    )
    INNER JOIN journal_entry_items ON
      journal_entry_items.tax_id = taxes.id
      AND
      journal_entry_items.account_id = accounts.id
    WHERE
      journal_entry_items.tax_declaration_item_id IS NOT NULL
    SQL
  end
end
