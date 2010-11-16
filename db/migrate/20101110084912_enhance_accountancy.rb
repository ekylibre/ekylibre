class EnhanceAccountancy < ActiveRecord::Migration
  PREFERENCES = {
    'accountancy.accountize.automatic'                   => 'bookkeep_automatically',
    'accountancy.accountize.draft_mode'                  => 'bookkeep_in_draft',
    'accountancy.accountize.detail_payments_in_deposits' => 'detail_payments_in_deposit_bookkeeping',
    'accountancy.accounts.charges'                       => 'charges_accounts',
    'accountancy.accounts.financial_banks'               => 'financial_banks_accounts',
    'accountancy.accounts.financial_payments_to_deposit' => 'financial_payments_to_deposit_accounts',
    'accountancy.accounts.financial_cashes'              => 'financial_cashes_accounts',
    'accountancy.accounts.financial_internal_transfers'  => 'financial_internal_transfers_accounts',
    'accountancy.accounts.third_clients'                 => 'third_clients_accounts',
    'accountancy.accounts.third_suppliers'               => 'third_suppliers_accounts',
    'accountancy.accounts.third_attorneys'               => 'third_attorneys_accounts',
    'accountancy.accounts.products'                      => 'products_accounts',
    'accountancy.accounts.capital_gains'                 => 'capital_gains_accounts',
    'accountancy.accounts.capital_losses'                => 'capital_losses_accounts',
    'accountancy.accounts.taxes_acquisition'             => 'taxes_acquisition_accounts',
    'accountancy.accounts.taxes_collected'               => 'taxes_collected_accounts',
    'accountancy.accounts.taxes_paid'                    => 'taxes_paid_accounts',
    'accountancy.accounts.taxes_balance'                 => 'taxes_balance_accounts',
    'accountancy.accounts.taxes_assimilated'             => 'taxes_assimilated_accounts',
    'accountancy.accounts.taxes_payback'                 => 'taxes_payback_accounts',
    'accountancy.cash_transfers.numeration'              => 'cash_transfers_sequence',
    'accountancy.entities.use_code_for_account_numbers'  => 'use_entity_codes_for_account_numbers',
    'accountancy.journals.cash'                          => 'cash_journal',
    'accountancy.journals.bank'                          => 'bank_journal',
    'accountancy.journals.purchases'                     => 'purchases_journal',
    'accountancy.journals.sales'                         => 'sales_journal',
    'accountancy.journals.various'                       => 'various_journal',
    'management.sales_invoices.numeration'               => 'sales_invoices_sequence',
    'management.deposits.numeration'                     => 'deposits_sequence',
    'management.incoming_deliveries.numeration'          => 'incoming_deliveries_sequence',
    'management.incoming_payments.numeration'            => 'incoming_payments_sequence',
    'management.purchase_orders.numeration'              => 'purchase_orders_sequence',
    'management.outgoing_deliveries.numeration'          => 'outgoing_deliveries_sequence',
    'management.outgoing_payments.numeration'            => 'outgoing_payments_sequence',
    'management.sales_orders.numeration'                 => 'sales_orders_sequence',
    'management.subscriptions.numeration'                => 'subscriptions_sequence',
    'management.transports.numeration'                   => 'transports_sequence',
    'relations.entities.numeration'                      => 'entities_sequence'
  }.to_a.sort


  def self.up
    # Change preferences
    add_column :companies, :language, :string, :null=>false, :default=>"eng"
    preferences = connection.select_all("SELECT * FROM #{quoted_table_name(:preferences)} WHERE name = 'general.language'")
    execute "UPDATE #{quoted_table_name(:companies)} SET language = CASE "+preferences.collect{|p| "WHEN id=#{p['company_id']} THEN '#{p['string_value']}'"}.join(" ")+" END" if preferences.size > 0
    execute "DELETE FROM #{quoted_table_name(:preferences)} WHERE name='general.language'"


    add_column :journal_entries,     :state, :string, :limit=>32, :null=>false, :default=>"draft" 
    add_column :journal_entries,     :balance, :decimal, :precision=>16, :scale=>2, :null=>false, :default=>0
    execute "UPDATE #{quoted_table_name(:journal_entries)} SET balance = (debit - credit)"
    execute "UPDATE #{quoted_table_name(:journal_entries)} SET state='confirmed' WHERE #{connection.not_boolean('draft')} AND #{connection.not_boolean('closed')}"
    execute "UPDATE #{quoted_table_name(:journal_entries)} SET state='closed' WHERE closed = #{quoted_true}"
    remove_column :journal_entries, :draft_mode
    remove_column :journal_entries, :draft
    remove_column :journal_entries, :closed
    remove_column :journal_entries, :position
    add_column :journal_entry_lines, :state, :string, :limit=>32, :null=>false, :default=>"draft"
    add_column :journal_entry_lines, :balance, :decimal, :precision=>16, :scale=>2, :null=>false, :default=>0
    execute "UPDATE #{quoted_table_name(:journal_entry_lines)} SET balance = (debit - credit)"
    execute "UPDATE #{quoted_table_name(:journal_entry_lines)} SET state='confirmed' WHERE #{connection.not_boolean('draft')} AND #{connection.not_boolean('closed')}"
    execute "UPDATE #{quoted_table_name(:journal_entry_lines)} SET state='closed' WHERE closed = #{quoted_true}"
    remove_column :journal_entry_lines, :draft
    remove_column :journal_entry_lines, :closed
    remove_column :journal_entry_lines, :expired_on

    

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

    add_column :journal_entry_lines, :expired_on, :date
    add_column :journal_entry_lines, :closed, :boolean, :null=>false, :default=>false
    add_column :journal_entry_lines, :draft, :boolean, :null=>false, :default=>false
    execute "UPDATE #{quoted_table_name(:journal_entry_lines)} SET closed = #{quoted_true} WHERE state='closed'"
    execute "UPDATE #{quoted_table_name(:journal_entry_lines)} SET draft = #{quoted_true} WHERE state='draft'"
    remove_column :journal_entry_lines, :balance
    remove_column :journal_entry_lines, :state
    add_column :journal_entries, :position, :integer
    add_column :journal_entries, :closed, :boolean, :null=>false, :default=>false
    add_column :journal_entries, :draft, :boolean, :null=>false, :default=>false
    add_column :journal_entries, :draft_mode, :boolean, :null=>false, :default=>false
    execute "UPDATE #{quoted_table_name(:journal_entries)} SET position = id"
    execute "UPDATE #{quoted_table_name(:journal_entries)} SET closed = #{quoted_true} WHERE state='closed'"
    execute "UPDATE #{quoted_table_name(:journal_entries)} SET draft = #{quoted_true} WHERE state='draft'"
    execute "UPDATE #{quoted_table_name(:journal_entries)} SET draft_mode = #{quoted_true} WHERE state='draft' AND debit = credit"
    remove_column :journal_entries,     :balance
    remove_column :journal_entries,     :state

    execute "INSERT INTO #{quoted_table_name(:preferences)}(string_value, company_id, created_at, updated_at, nature, name) SELECT language, id, created_at, updated_at, 'string', 'general.language' FROM #{quoted_table_name(:companies)}"
    remove_column :companies, :language
  end
end
