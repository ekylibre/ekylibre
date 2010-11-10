class EnhanceAccountancy < ActiveRecord::Migration
  PREFERENCES = {
    'accountancy.accountize.automatic' => 'accountize_automatically',
    'accountancy.accountize.draft_mode' => 'accountize_in_draft',
    'accountancy.accountize.detail_payments_in_deposits' => 'detail_payment_in_deposit_accountizing',
    'accountancy.accounts.charges' => 'charges_accounts',
    'accountancy.accounts.financial_banks' => 'financial_banks_accounts',
    'accountancy.accounts.financial_payments_to_deposit' => 'financial_payments_to_deposit_accounts',
    'accountancy.accounts.financial_cashes' => 'financial_cashes_accounts',
    'accountancy.accounts.financial_internal_transfers' => 'financial_internal_transfers_accounts',
    'accountancy.accounts.third_clients' => 'third_clients_accounts',
    'accountancy.accounts.third_suppliers' => 'third_suppliers_accounts',
    'accountancy.accounts.third_attorneys' => 'third_attorneys_accounts',
    'accountancy.accounts.products' => 'products_accounts',
    'accountancy.accounts.capital_gains' => 'capital_gains_accounts',
    'accountancy.accounts.capital_losses' => 'capital_losses_accounts',
    'accountancy.accounts.taxes_acquisition' => 'taxes_acquisition_accounts',
    'accountancy.accounts.taxes_collected' => 'taxes_collected_accounts',
    'accountancy.accounts.taxes_paid' => 'taxes_paid_accounts',
    'accountancy.accounts.taxes_balance' => 'taxes_balance_accounts',
    'accountancy.accounts.taxes_assimilated' => 'taxes_assimilated_accounts',
    'accountancy.accounts.taxes_payback' => 'taxes_payback_accounts',
    'accountancy.cash_transfers.numeration' => 'cash_transfers_sequence',
    'accountancy.entities.use_code_for_account_numbers' => 'use_entity_codes_for_account_numbers',
    'accountancy.journals.cash'      => 'cash_journal',
    'accountancy.journals.bank'      => 'bank_journal',
    'accountancy.journals.purchases' => 'purchases_journal',
    'accountancy.journals.sales'     => 'sales_journal',
    'accountancy.journals.various'   => 'various_journal',
    'management.sales_invoices.numeration' => 'sales_invoices_sequence',
    'management.deposits.numeration' => 'deposits_sequence',
    'management.incoming_deliveries.numeration' => 'incoming_deliveries_sequence',
    'management.incoming_payments.numeration' => 'incoming_payments_sequence',
    'management.purchase_orders.numeration' => 'purchase_orders_sequence',
    'management.outgoing_deliveries.numeration' => 'outgoing_deliveries_sequence',
    'management.outgoing_payments.numeration' => 'outgoing_payments_sequence',
    'management.sales_orders.numeration' => 'sales_orders_sequence',
    'management.subscriptions.numeration' => 'subscriptions_sequence',
    'relations.entities.numeration' => 'entities_sequence'
  }.to_a.sort


  def self.up
    #     # Re-mark all letters company by company in order to set the global mark which permits to disambigute
    #     # every letter across all accounts and time
    #     add_column :companies, :last_letter, :string
    #     add_column :companies, :available_letters, :text
    #     for company in connection.select_all("SELECT * FROM #{quoted_table_name(:companies)}")
    #       nl = ""
    #       for line in connection.select_all("SELECT DISTINCT account_id, letter FROM #{quoted_table_name(:journal_entry_lines)} WHERE company_id=#{company['id']} AND letter IS NOT NULL AND letter != ''")
    #         unless line['letter'].blank?
    #           nl = (nl.blank? ? "A" : nl.succ)
    #           execute "UPDATE #{quoted_table_name(:journal_entry_lines)} SET letter='#{nl}' WHERE company_id=#{company['id']} AND account_id=#{line['account_id']} AND letter='#{line['letter']}'"
    #         end
    #       end
    #       execute "UPDATE #{quoted_table_name(:companies)} SET last_letter = '#{nl}' WHERE id=#{company['id']}"
    #     end
    #     remove_column :accounts, :last_letter
    
    # Change preferences
    add_column :companies, :language, :string, :null=>false, :default=>"eng"
    preferences = connection.select_all("SELECT * FROM #{quoted_table_name(:preferences)} WHERE name = 'general.language'")
    execute "UPDATE #{quoted_table_name(:companies)} SET language = CASE "+preferences.collect{|p| "WHEN id=#{p['company_id']} THEN '#{p['string_value']}'"}.join(" ")+" END" if preferences.size > 0
    execute "DELETE FROM #{quoted_table_name(:preferences)} WHERE name='general.language'"

    for o, n in PREFERENCES
      execute "UPDATE #{quoted_table_name(:preferences)} SET name='#{n}' WHERE name='#{o}'"
    end

    # Change private directory structure
    for cdir in Dir.glob(File.join(Ekylibre.private_directory, "*"))
      FileUtils.mkdir_p File.join(cdir, ".documents")
      FileUtils.mv Dir.glob(File.join(cdir, "*")), File.join(cdir, ".documents")
      FileUtils.mv File.join(cdir, ".documents"), File.join(cdir, "documents")
    end
  end

  def self.down
    for cdir in Dir.glob(File.join(Ekylibre.private_directory, "*"))
      FileUtils.mkdir_p File.join(cdir, "documents")
      FileUtils.mv File.join(cdir, "documents"), File.join(cdir, ".documents")
      FileUtils.mv Dir.glob(File.join(cdir, ".documents", "*")), cdir
      FileUtils.rmdir File.join(cdir, ".documents")
    end

    for n, o in PREFERENCES.reverse
      execute "UPDATE #{quoted_table_name(:preferences)} SET name='#{n}' WHERE name='#{o}'"
    end

    execute "INSERT INTO #{quoted_table_name(:preferences)}(string_value, company_id, created_at, updated_at, nature, name) SELECT language, id, created_at, updated_at, 'string', 'general.language' FROM #{quoted_table_name(:companies)}"
    remove_column :companies, :language

    #     # Re-mark all letters account by account
    #     add_column :accounts, :last_letter, :string
    #     for account in connection.select_all("SELECT * FROM #{quoted_table_name(:accounts)} WHERE id IN (SELECT DISTINCT account_id FROM #{quoted_table_name(:journal_entry_lines)} WHERE letter IS NOT NULL AND letter != '')")
    #       nl = ""
    #       for line in connection.select_all("SELECT DISTINCT letter FROM #{quoted_table_name(:journal_entry_lines)} WHERE account_id=#{account['id']} AND letter IS NOT NULL")
    #         unless line['letter'].blank?
    #           nl = (nl.blank? ? "AAA" : nl.succ)
    #           execute "UPDATE #{quoted_table_name(:journal_entry_lines)} SET letter='#{nl}' WHERE account_id=#{account['id']} AND letter='#{line['letter']}'"
    #         end
    #       end
    #       execute "UPDATE #{quoted_table_name(:accounts)} SET last_letter = '#{nl}' WHERE id=#{account['id']}"
    #     end
    #     remove_column :companies, :available_letters
    #     remove_column :companies, :last_letter
  end
end
