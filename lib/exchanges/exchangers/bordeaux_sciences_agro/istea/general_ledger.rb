
Exchanges.add_importer :bordeaux_sciences_agro_istea_general_ledger do |file, w|

  rows = CSV.read(file, encoding: "CP1252", col_sep: ";")
  w.count = rows.size

  rows.each do |row|
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
      :what_on => row[12]
    }.to_struct

    # Adds the journal entry item with the dependencies
    fy = FinancialYear.at(r.printed_on)
    unless entry = JournalEntry.find_by(journal_id: r.journal.id, number: r.entry_number)
      number = r.entry_number
      number = r.journal.code + (10_000_000_000 + rand(10_000_000_000)).to_s(36) if number.blank?
      entry = r.journal.entries.create!(:printed_on => r.printed_on.to_datetime, :number => number.mb_chars.upcase)
    end
    column = (r.debit.zero? ? :credit : :debit)
    entry.send("add_#{column}", r.entry_name, r.account, r.send(column))

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

    w.check_point
  end

end
