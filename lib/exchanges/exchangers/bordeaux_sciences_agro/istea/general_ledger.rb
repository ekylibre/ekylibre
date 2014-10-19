
Exchanges.add_importer :bordeaux_sciences_agro_istea_general_ledger do |file, w|

  rows = CSV.read(file, encoding: "CP1252", col_sep: ";").collect do |row|
    row << FinancialYear.at(Date.civil(*row[3].split(/\-/).map(&:to_i))).code
  end

  w.count = rows.collect{|a| a[13] + a[3] + a[4].to_s}.uniq.size

  entry = nil
  old = nil
  rows.sort{|a,b| a[13] + a[3] + a[4].to_s <=> b[13] + b[3] + b[4].to_s}.each_with_index do |row, index|
    r = {
      :account => Account.get(row[0]),
      :journal => Journal.find_by(code: row[1]) || Journal.create!(name: "Journal #{row[1]}", code: row[1], currency: "EUR"),
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
      :what_on => row[12],
      financial_year_code: row[13]
    }.to_struct

    if old.present? and (old.entry_number != r.entry_number or old.printed_on != r.printed_on or old.journal != r.journal)
      if entry and entry[:items_attributes]
        if items = entry[:items_attributes].values
          debit = items.map{|v| v[:real_debit]}.sum
          credit = items.map{|v| v[:real_credit]}.sum
          if debit != credit
            Rails.logger.warn "Error on JournalEntry ##{entry[:number]} (D: #{debit}, C: #{credit}, B: #{debit - credit})".red
          end
        end
        JournalEntry.create!(entry)
        entry = nil
        w.check_point
      else
        raise "What ???"
      end
    end

    # Adds the journal entry item with the dependencies
    unless entry
      fy = FinancialYear.at(r.printed_on)
      number = r.entry_number
      number = r.journal.code + (10_000_000_000 + rand(10_000_000_000)).to_s(36) if number.blank?
      number = number.mb_chars.upcase
      while JournalEntry.where(number: number).any?
        number.succ!
      end
      entry = {
        printed_on: r.printed_on,
        journal: r.journal,
        number: number,
        financial_year: fy
      }
    end

    entry[:items_attributes] ||= {}
    entry[:items_attributes][index.to_s] = {real_debit: r.debit, real_credit: r.credit, account: r.account, name: r.entry_name}

    # Adds a real entity with known information
    if r.account.number.match(/^4(0|1)\d/)
      last_name = r.entity_name.mb_chars.capitalize
      unless entity = Entity.where("last_name ILIKE ?", last_name).first
        entity = LegalEntity.create!(last_name: last_name, nature: "legal_entity", first_met_at: r.printed_on)
      end
      if entity.first_met_at and r.printed_on and r.printed_on < entity.first_met_at
        entity.first_met_at = r.printed_on
      end
      if r.account.number.match(/^401/)
        entity.supplier = true
        entity.supplier_account_id = r.account.id
      end
      if r.account.number.match(/^411/)
        entity.client = true
        entity.client_account_id = r.account.id
      end
      entity.save
    end

    old = r
  end

end
