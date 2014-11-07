Exchanges.add_importer :legrain_epicea_journals do |file, w|
  rows = CSV.read(file, headers: true, encoding: "cp1252", col_sep: ";")
  w.count = rows.count
  journal_nature_by_code = {
    AC: :purchases,
    B: :bank,
    OD: :various,
    VT: :sales
  }.with_indifferent_access

  entry = nil
  rows.each_with_index do |row, index|
    r = {
      debit: row[6].to_f,
      credit: row[7].to_f,
      account: Account.find_by(number: row[3]) || Account.create!(number: row[3], name: row[4]),
      nature: journal_nature_by_code[row[0].sub(/[0-9]/,'')],
      printed_on: Date.parse(row[2]),
      number: row[1],
      code: row[0],
      label: row[5]
    }.to_struct

    entry_item = {
      real_debit: r.debit,
      real_credit: r.credit,
      account: r.account,
      name: r.label
    }

    if entry.present? && r.number != entry[:number]
      JournalEntry.create!(entry)
      entry = nil
    end

    j = Journal.find_by(code: r.code) || Journal.create!(name: "Journal #{r.code}", code: r.code, currency: "EUR", nature: r.nature)
    entry ||= {
      printed_on: r.printed_on,
      journal: j,
      number: r.number,
      financial_year: FinancialYear.at(r.printed_on),
      item_attribute: {}
    }

    entry[:item_attribute][index.to_s] = entry_item

    w.check_point
  end
end
