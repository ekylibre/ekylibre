class RepairsNullJournals < ActiveRecord::Migration
  def up
    execute 'UPDATE sale_natures SET with_accounting = FALSE WHERE with_accounting = TRUE AND journal_id NOT IN (SELECT id FROM journals)'
    execute 'UPDATE purchase_natures SET with_accounting = FALSE WHERE with_accounting = TRUE AND journal_id NOT IN (SELECT id FROM journals)'
    execute 'UPDATE incoming_payment_modes SET with_deposit = FALSE WHERE with_deposit = TRUE AND depositables_journal_id NOT IN (SELECT id FROM journals)'
  end
end
