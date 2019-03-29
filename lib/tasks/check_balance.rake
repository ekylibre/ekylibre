namespace :check_balance do
  task equality: :environment do
    Ekylibre::Tenant.switch! ENV['TENANT']
    puts '----------------Start____________'

    journal_entry_debit = 0
    journal_entry_credit = 0
    JournalEntry.find_each do |journal_entry|
      je_debit        = journal_entry.debit
      je_credit       = journal_entry.credit
      je_items        = journal_entry.items
      je_items_debit  = je_items.sum(:debit)
      je_items_credit = je_items.sum(:credit)

      journal_entry_debit += je_debit.to_f
      journal_entry_credit += je_credit.to_f
      unless check_decimal([je_debit, je_credit, je_items_debit, je_items_credit])
        puts "Decimal error in #{journal_entry.id}"
      end
      if je_debit != je_items_debit && je_credit != je_items_credit
        puts "Equality error in #{journal_entry.id}"
      end
      if je_debit - je_credit != 0
        puts "Debit and credit are different in #{journal_entry.id}"
      end

      puts "!!!! Debit and credit (sum of journal entry items) are different in JournalEntry: #{journal_entry.id} !!!" if journal_entry.items.sum(:debit) != journal_entry.items.sum(:credit)
    end

    puts 'journal_entry-debit != journal_entry_credit' if journal_entry_debit != journal_entry_credit

    total_debit  = JournalEntry.sum(:debit)
    total_credit = JournalEntry.sum(:credit)
    total_absolute_debit = JournalEntry.sum(:absolute_debit)
    total_absolute_credit = JournalEntry.sum(:absolute_credit)

    puts 'total_credit != total_debit' if total_credit != total_debit

    Account.find_each do |account|
      totals = account.totals
      unless check_decimal([totals[:credit], totals[:debit], totals[:balance_credit], totals[:balance_debit], totals[:balance]])
        puts "Decimal error in account totals. account: #{account.id}"
      end
    end
    puts '----------Stop__________'
  end

  def check_decimal(array)
    array.each do |value|
      return false if value.to_f.to_s.split('.')[1].length > 2
    end
  end
end
