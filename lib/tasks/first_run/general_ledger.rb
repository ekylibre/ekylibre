# -*- coding: utf-8 -*-
load_data :general_ledger do |loader|

  file = loader.path("istea", "general_ledger.txt")
  if file.exist?
    loader.count :general_ledger do |w|
      #############################################################################
      # Import accountancy
      journals = {}
      journals_file = loader.path("istea", "journals.yml")
      if journals_file.exist?
        journals = YAML.load_file(journals_file).stringify_keys.with_indifferent_access
      end

      # year = 2010
      # fy = FinancialYear.first
      # fy.started_at = Date.civil(year,  1,  1)
      # fy.stopped_at = Date.civil(year, 12, 31)
      # fy.code = "EX#{year}"
      # fy.save!

      CSV.foreach(file, :encoding => "CP1252", :col_sep => ";") do |row|
        jname = (journals[row[1]] || row[1]).capitalize
        r = OpenStruct.new(:account => Account.get(row[0]),
                           :journal => Journal.find_by_name(jname) || Journal.create!(:name => jname, :code => row[1], :currency => "EUR"),
                           :page_number => row[2], # What's that ?
                           :printed_on => Date.civil(*row[3].split(/\-/).map(&:to_i)),
                           :entry_number => row[4].to_s.strip.mb_chars.upcase.to_s.gsub(/[^A-Z0-9]/, ''),
                           :entity_name => row[5],
                           :entry_name => row[6],
                           :debit => row[7].to_d,
                           :credit => row[8].to_d,
                           :vat => row[9],
                           :comment => row[10],
                           :letter => row[11],
                           :what_on => row[12])


        fy = FinancialYear.at(r.printed_on)
        unless entry = JournalEntry.find_by(:journal_id => r.journal.id, :number => r.entry_number)
          number = r.entry_number
          number = r.journal.code + rand(10000000000).to_s(36) if number.blank?
          entry = r.journal.entries.create!(:printed_at => r.printed_on.to_datetime, :number => number.mb_chars.upcase)
        end
        column = (r.debit.zero? ? :credit : :debit)
        entry.send("add_#{column}", r.entry_name, r.account, r.send(column))

        w.check_point
      end

    end

  end

end
