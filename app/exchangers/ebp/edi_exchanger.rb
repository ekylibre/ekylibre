module EBP
  class EDIExchanger < ActiveExchanger::Base
    def import
      w.count = `wc -l #{file}`.split.first.to_i - 6

      File.open(file, 'rb:CP1252') do |f|
        header = begin
                   f.readline.strip
                 rescue
                   nil
                 end
        unless header == 'EBP.EDI'
          raise ActiveExchanger::NotWellFormedFileError, "Start is not valid. Got #{header.inspect}."
        end
        encoding = f.readline
        f.readline
        owner = f.readline
        started_on = f.readline
        started_on = Date.civil(started_on[4..7].to_i, started_on[2..3].to_i, started_on[0..1].to_i).to_datetime.beginning_of_day
        stopped_on = f.readline
        stopped_on = Date.civil(stopped_on[4..7].to_i, stopped_on[2..3].to_i, stopped_on[0..1].to_i).to_datetime.end_of_day
        ActiveRecord::Base.transaction do
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
              unless Account.find_by(number: line[1])
                Account.create!(number: line[1], name: line[2])
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
              account = Account.create_with(name: line[1]).find_or_create_by!(number: line[1])
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
