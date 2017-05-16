namespace :check_balance do
  task equality: :environment do
    Ekylibre::Tenant.switch! ENV['TENANT']
    puts "----------------Start____________"
    JournalEntry.find_each do |journal_entry|
      je_debit        = journal_entry.debit
      je_credit       = journal_entry.credit
      je_items        = journal_entry.items
      je_items_debit  = je_items.sum(:debit)
      je_items_credit = je_items.sum(:credit)
      if je_debit != je_items_debit && je_credit != je_items_credit && je_debit + je_credit != 0
        puts 'aie aie aie'
      end
    end
    puts "----------Stop__________"
  end
end
