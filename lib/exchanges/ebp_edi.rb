module Exchanges

  class EbpEdi < Exchanger


    # Import from simple files EBP.EDI
    def self.import(file, options={})
      File.open(file, "rb:CP1252") do |f|
        header = f.readline.strip
        unless header == "EBP.EDI"
          raise NotWellFormedFileError.new("Start is not valid. Got #{header.inspect}.")
        end
        encoding = f.readline
        f.readline
        owner = f.readline
        started_at = f.readline
        started_at = Date.civil(started_at[4..7].to_i, started_at[2..3].to_i, started_at[0..1].to_i).to_datetime.beginning_of_day
        stopped_at = f.readline
        stopped_at = Date.civil(stopped_at[4..7].to_i, stopped_at[2..3].to_i, stopped_at[0..1].to_i).to_datetime.end_of_day
        ActiveRecord::Base.transaction do
          while 1
            begin
              line = f.readline.gsub(/\n/, '')
            rescue
              break
            end
            unless FinancialYear.find_by_started_at_and_stopped_at(started_at, stopped_at)
              FinancialYear.create!(started_at: started_at, stopped_at: stopped_at)
            end
            line = line.encode("utf-8").split(/\;/)
            if line[0] == "C"
              unless Account.find_by_number(line[1])
                Account.create!(number: line[1], name: line[2])
              end
            elsif line[0] == "E"
              unless journal = Journal.find_by_code(line[3])
                journal = Journal.create!(code: line[3], name: line[3], nature: :various, closed_at: (started_at - 1.day).end_of_day)
              end
              number = line[4].blank? ? "000000" : line[4]
              line[2] = Date.civil(line[2][4..7].to_i, line[2][2..3].to_i, line[2][0..1].to_i).to_datetime
              unless entry = journal.entries.find_by_number_and_printed_at(number, line[2])
                entry = journal.entries.create!(number: number, printed_at: line[2])
              end
              unless account = Account.find_by_number(line[1])
                account = Account.create!(number: line[1], name: line[1])
              end
              line[8] = line[8].strip.to_f
              if line[7] == "D"
                entry.add_debit(line[6], account, line[8], letter: line[10])
              else
                entry.add_credit(line[6], account, line[8], letter: line[10])
              end
            end
          end
        end
      end
    end

  end

end
