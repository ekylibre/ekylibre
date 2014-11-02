
Exchanges.add_importer :bordeaux_sciences_agro_istea_general_ledger do |file, w|

  rows = CSV.read(file, encoding: "CP1252", col_sep: ";")
  rows.collect!do |row|
    row << FinancialYear.at(Date.parse(row[3])).code
  end
  w.count = rows.size
  w_count = (rows.size > 100 ? rows.size / 100 : 100)
  EMPTY = ''
  rows.sort!{|a,b| a[13] + a[3] << (a[4] || EMPTY) <=> b[13] + b[3] << (b[4] || EMPTY) }

  count = 0
  entry,old = nil, nil
  used_numbers, accounts, journals, entities = {}, {}, {}, {}
  rows.each_with_index do |row, index|
    entry_number = row[4].to_s
    entry_number.gsub!(/[^0-9a-z]/i, '')
    accounts[row[0]] ||= Account.get(row[0])
    journals[row[1]] ||= Journal.find_by(code: row[1]) || Journal.create!(name: "Journal #{row[1]}", code: row[1], currency: "EUR")
    r = {
      :account => accounts[row[0]],
      :journal => journals[row[1]],
      :page_number => row[2], # What's that ?
      :printed_on => Date.parse(row[3]),
      :entry_number => entry_number,
      :entity_name => row[5],
      :entry_name => row[6],
      :debit => row[7].to_d,
      :credit => row[8].to_d,
      :vat => row[9],
      :comment => row[10],
      :letter => row[11],
      :what_on => row[12],
      :financial_year_code => row[13]
    }.to_struct

    if old.present? and (old.entry_number != r.entry_number or old.printed_on != r.printed_on or old.journal != r.journal)
      if entry and entry[:items_attributes]
        je = JournalEntry.create!(entry)
        if je.real_debit != je.real_credit
          Rails.logger.warn "Error on JournalEntry ##{entry[:number]} (D: #{je.debit}, C: #{je.credit}, B: #{je.debit - je.credit})".red
        end
        entry = nil
      else
        raise "What ???"
      end
    end

    # Adds the journal entry item with the dependencies
    unless entry
      fy = FinancialYear.at(r.printed_on)
      number = r.entry_number
      number = r.journal.code + (10_000_000_000 + rand(10_000_000_000)).to_s(36) if number.blank?
      number.upcase!
      while used_numbers[number]
        number.succ!
      end
      used_numbers[number] = true
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
      modified = false
      entities[last_name] ||= Entity.where("last_name ILIKE ?", last_name).first || LegalEntity.create!(last_name: last_name, nature: "legal_entity", first_met_at: r.printed_on)
      entity = entities[last_name]
      if entity.first_met_at and r.printed_on and r.printed_on < entity.first_met_at
        entity.first_met_at = r.printed_on
        modified = true
      end
      account_number = r.account.number
      if account_number.match(/^401/)
        entity.supplier = true
        entity.supplier_account_id = r.account.id
        modified = true
      end
      if account_number.match(/^411/)
        entity.client = true
        entity.client_account_id = r.account.id
        modified = true
      end
      entity.save if modified
    end

    old = r
    count += 1
    w.check_point if count % w_count
  end

  count, entry,old, used_numbers, accounts, journals, entities = nil
  GC.start

end
