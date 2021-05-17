# Tenant tasks
namespace :maintenance do
  namespace :journal_entry_items do
    desc 'Generate isacompta letters for journal_entry_items'
    task generate_isacompta_letters: :environment do
      Ekylibre::Tenant.switch_each do
        puts "Updating #{Ekylibre::Tenant.current} tenant"
        FinancialYear.find_each do |financial_year|
          isacompta_letter = '000'
          letters = financial_year.journal_entry_items.where.not(letter: nil)
            .select(:letter).distinct
            .pluck(:letter).map { |letter| letter.remove('*') }.uniq.sort
          letters.each do |letter|
            items = financial_year.journal_entry_items
              .where('letter = ? OR letter = ?', letter, letter + '*')
            puts "Updating financial_year_id: #{financial_year.id} (#{items.count} items)"
            items.update_all(isacompta_letter: isacompta_letter)
            isacompta_letter = next_isacompta_letter(isacompta_letter)
          end
        end
        JournalEntryItem.where("RIGHT(letter, 1) = '*'").update_all("isacompta_letter = '#' || isacompta_letter")
      end
    end
  end
end

def next_isacompta_letter(last_isacompta_letter)
  if last_isacompta_letter == 'ZZZ'
    raise 'ZZZ is the max value of isacompta_letter'
  elsif last_isacompta_letter == '999'
    '00A'
  elsif last_isacompta_letter.nil?
    '000'
  else
    last_isacompta_letter.succ
  end
end
