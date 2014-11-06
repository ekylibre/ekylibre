Exchanges.add_importer :legrain_epicea_general_ledger do |file, w|
  rows = CSV.read(file, headers: true, encoding: "cp1252", col_sep: ";", quote_char: "'")
  w.count = rows.count

  rows.each do |row|
    w.check_point
  end
end
