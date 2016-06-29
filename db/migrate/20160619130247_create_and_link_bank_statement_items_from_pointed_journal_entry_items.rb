class CreateAndLinkBankStatementItemsFromPointedJournalEntryItems < ActiveRecord::Migration
  def up
    each_pointed_journal_entry_items_by_cash_id do |_, journal_entry_items|
      bank_statement_letter = 'A'
      journal_entry_items.each do |journal_entry_item|
        create_bank_statement_item journal_entry_item, bank_statement_letter
        update_journal_entry_item_letter journal_entry_item, bank_statement_letter
        bank_statement_letter.succ!
      end
    end
  end

  def down
    pointed_journal_entry_items.each do |journal_entry_item|
      update_journal_entry_item_letter journal_entry_item, nil
    end
    execute 'TRUNCATE TABLE bank_statement_items'
  end

  def pointed_journal_entry_items
    execute <<-SQL
      SELECT
        journal_entry_items.id          AS id,
        journal_entry_items.name        AS name,
        journal_entry_items.real_debit  AS real_debit,
        journal_entry_items.real_credit AS real_credit,
        journal_entry_items.printed_on  AS printed_on,
        bank_statements.id              AS bank_statement_id,
        bank_statements.currency        AS bank_statement_currency,
        bank_statements.cash_id         AS cash_id
      FROM
        journal_entry_items
      INNER JOIN
        bank_statements
      ON
        bank_statements.id = journal_entry_items.bank_statement_id
    SQL
  end

  def each_pointed_journal_entry_items_by_cash_id(&block)
    pointed_journal_entry_items.group_by { |i| i['cash_id'] }.each(&block)
  end

  def create_bank_statement_item(entry_item, bank_statement_letter)
    execute <<-SQL
      INSERT INTO bank_statement_items(
        created_at,
        updated_at,
        bank_statement_id,
        name,
        credit,
        debit,
        currency,
        transfered_on,
        letter
      )
      VALUES (
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP,
        #{quote(entry_item['bank_statement_id'])},
        #{quote(entry_item['name'])},
        #{quote(entry_item['real_debit'])},
        #{quote(entry_item['real_credit'])},
        #{quote(entry_item['bank_statement_currency'])},
        #{quote(entry_item['printed_on'])},
        #{quote(bank_statement_letter)}
      )
    SQL
  end

  def update_journal_entry_item_letter(entry_item, bank_statement_letter)
    execute <<-SQL
      UPDATE
        journal_entry_items
      SET
        updated_at = CURRENT_TIMESTAMP,
        bank_statement_letter = #{quote(bank_statement_letter)}
      WHERE
        id = #{quote(entry_item['id'])}
    SQL
  end

  def quote(*args)
    connection.quote(*args)
  end
end
