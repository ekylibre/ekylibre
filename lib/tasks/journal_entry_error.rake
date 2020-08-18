namespace :journal_entry_error do
  desc "Find invalid journal entries : journal entries with double number"
  task find_invalid_journal_entries: :environment do
    set_journal_parmeters
    find_invalid_journal_entries
    puts "Number of invalid JournalEntry : #{@invalids.count}"
    puts "Id of invalid JournalEntry : #{@invalids.map(&:id)}"
  end

  desc "Update the JournalEntry number of JournalEntry with double number"
  task make_valid_journal_entries: :environment do
    set_journal_parmeters
    find_invalid_journal_entries
    @invalids.each do |invalid|
      result = invalid.update(number: invalid.journal.next_number)
      puts "Update JournalEntry : #{invalid.id}".green if result
      puts "Error when update JournalEntry : #{invalid.id}, number: #{invalid.number}, message: #{invalid.errors.full_messages}".red unless result
    end
  end

  private

    def set_journal_parmeters
      puts 'Enter tenant name :'.blue
      @tenant = STDIN.gets.chomp
      puts "#{Ekylibre::Tenant.switch!(@tenant)}".yellow
    end

    def find_invalid_journal_entries
      list_of_invalid = JournalEntry.where(state: [:draft, :confirmed]).select(:number).group(:number).having("count(*) > 1").all
      @invalids = list_of_invalid.map { |a| JournalEntry.where(number: a.number, state: [:confirmed, :draft]) }.flatten
    end

end
