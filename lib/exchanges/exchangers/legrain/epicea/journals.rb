Exchanges.add_importer :legrain_epicea_journals do |file, w|
  rows = CSV.read(file, headers: true, encoding: "cp1252", col_sep: ";", skip_blanks: true)
  w.count = rows.count
  journal_nature_by_code = {
    AC: :purchases,
    B: :bank,
    OD: :various,
    VT: :sales
  }.with_indifferent_access

  entry = nil
  ActiveRecord::Base.transaction do
    #First of all: identify and create the first financial year of the file
    old, first_financial_year_beginning, current_financial_year = nil, nil, nil
    rows.each do |row|
      old ||= row[1].to_s.chars[2..3].join
      current = row[1].to_s.chars[2..3].join
      if current != old
        first_financial_year_beginning = (Date.parse(row[2]) - 1.year).beginning_of_month
      break
      end
    end
    current_financial_year = FinancialYear.create! started_on: first_financial_year_beginning

    rows.each_with_index do |row, index|
      begin
        w.check_point
        next
      end unless row.fields.compact.present?
      unless a = Account.find_by(number: row[3].to_s.upcase)
        a = Account.create!(number: row[3].to_s.upcase, name: row[5].to_s)
      end
      r = {
        debit: row[6].to_f,
        credit: row[7].to_f,
        account: a,
        nature: journal_nature_by_code[row[0].sub(/[0-9]/,'')],
        printed_on: Date.parse(row[2]),
        number: row[1],
        code: row[0].to_s.upcase,
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

      unless fy = FinancialYear.at(r.printed_on)
        fy = current_financial_year.find_or_create_next!
        current_financial_year = fy
      end

      unless j = Journal.find_by(code: r.code)
        j = Journal.create!(name: "Journal #{r.code}", code: r.code, currency: "EUR", nature: r.nature)
      end

      entry ||= {
        printed_on: r.printed_on,
        journal: j,
        number: r.number,
        financial_year: fy,
        currency: "EUR",
        items_attributes: {}
      }
      entry[:items_attributes][index.to_s] = entry_item

      # manage the last row
      if index == rows.count - 1
        JournalEntry.create!(entry)
        entry = nil
      end
      w.check_point
    end
  end
end
