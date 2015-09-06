class EBP::EDIExchanger < ActiveExchanger::Base
  def import
    w.count = `wc -l #{file}`.split.first.to_i - 6

    File.open(file, 'rb:CP1252') do |f|
      header = begin
                 f.readline.strip
               rescue
                 nil
               end
      unless header == 'EBP.EDI'
        fail ActiveExchanger::NotWellFormedFileError.new("Start is not valid. Got #{header.inspect}.")
      end
      encoding = f.readline
      f.readline
      owner = f.readline
      started_on = f.readline
      started_on = Date.civil(started_on[4..7].to_i, started_on[2..3].to_i, started_on[0..1].to_i).to_datetime.beginning_of_day
      stopped_on = f.readline
      stopped_on = Date.civil(stopped_on[4..7].to_i, stopped_on[2..3].to_i, stopped_on[0..1].to_i).to_datetime.end_of_day
      ActiveRecord::Base.transaction do
        loop do
          begin
            line = f.readline.gsub(/\n/, '')
          rescue
            break
          end
          unless FinancialYear.find_by_started_on_and_stopped_on(started_on, stopped_on)
            FinancialYear.create!(started_on: started_on, stopped_on: stopped_on)
          end
          line = line.encode('utf-8').split(/\;/)
          if line[0] == 'C'
            unless Account.find_by_number(line[1])
              Account.create!(number: line[1], name: line[2])
            end
          elsif line[0] == 'E'
            unless journal = Journal.find_by_code(line[3])
              journal = Journal.create!(code: line[3], name: line[3], nature: :various, closed_at: (started_on - 1.day).end_of_day)
            end
            number = line[4].blank? ? '000000' : line[4]
            line[2] = Date.civil(line[2][4..7].to_i, line[2][2..3].to_i, line[2][0..1].to_i).to_datetime
            unless entry = journal.entries.find_by_number_and_printed_on(number, line[2])
              entry = journal.entries.create!(number: number, printed_on: line[2])
            end
            unless account = Account.find_by_number(line[1])
              account = Account.create!(number: line[1], name: line[1])
            end
            line[8] = line[8].strip.to_f
            if line[7] == 'D'
              entry.add_debit(line[6], account, line[8], letter: line[10])
            else
              entry.add_credit(line[6], account, line[8], letter: line[10])
            end
          end
          w.check_point
        end
      end
    end
  end
end
