# frozen_string_literal: true

module EBP
  class EDIExchanger < ActiveExchanger::Base
    category :accountancy
    vendor :ebp

    def import
      w.count = `wc -l #{file}`.split.first.to_i - 6

      File.open(file, 'rb:CP1252') do |f|
        header = begin
                   f.readline.strip
                 rescue
                   nil
                 end
        unless header == 'EBP.EDI'
          raise ActiveExchanger::NotWellFormedFileError.new("Start is not valid. Got #{header.inspect}.")
        end

        encoding = f.readline
        f.readline
        f.readline # => owner
        started_on = f.readline
        started_on = Date.civil(started_on[4..7].to_i, started_on[2..3].to_i, started_on[0..1].to_i).to_datetime.beginning_of_day
        stopped_on = f.readline
        stopped_on = Date.civil(stopped_on[4..7].to_i, stopped_on[2..3].to_i, stopped_on[0..1].to_i).to_datetime.end_of_day
        ApplicationRecord.transaction do
          entries = {}
          loop do
            begin
              line = f.readline.delete("\n")
            rescue
              break
            end
            unless FinancialYear.find_by(started_on: started_on, stopped_on: stopped_on)
              FinancialYear.create!(started_on: started_on, stopped_on: stopped_on)
            end
            line = line.encode('utf-8').split(/\;/)
            if line[0] == 'C'
              unless Account.find_by(number: [line[1], line[1].ljust(Preference[:account_number_digits], '0')])
                # Attributes are set for a general account by default
                attributes = {
                  name: line[2],
                  already_existing: true,
                  nature: 'general',
                  number: line[1]
                }
                if line[1].start_with?('401', '411')
                  attributes[:centralizing_account_name] = line[1].start_with?('401') ? 'suppliers' : 'clients'
                  attributes[:auxiliary_number] = line[1][3, line[1].length]
                  attributes[:number] = line[1][0...3]
                  attributes[:nature] = 'auxiliary'
                end
                Account.create!(attributes)
              end
            elsif line[0] == 'E'
              journal = Journal.create_with(name: line[3], nature: :various, closed_on: (started_on - 1.day).end_of_day).find_or_create_by!(code: line[3])
              number = line[4].blank? ? '000000' : line[4]
              line[2] = Date.civil(line[2][4..7].to_i, line[2][2..3].to_i, line[2][0..1].to_i).to_datetime
              unless entries[number]
                entries[number] = {
                  printed_on: line[2],
                  journal: journal,
                  number: number,
                  currency: journal.currency,
                  items: []
                }
              end
              unless account = Account.find_by(number: [line[1], line[1].ljust(Preference[:account_number_digits], '0')])
                account = Account.create!(name: line[1], number: line[1], already_existing: true)
              end
              entries[number][:items] << JournalEntryItem.new_for(line[6], account, line[8].strip.to_f, letter: line[10], credit: (line[7] != 'D'))
            end
            w.check_point
          end

          w.reset!(entries.keys.count)
          entries.each do |_number, entry|
            JournalEntry.create!(entry)
            w.check_point
          end
        end
      end
    end
  end
end
