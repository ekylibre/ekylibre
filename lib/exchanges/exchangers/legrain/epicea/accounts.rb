Exchanges.add_importer :legrain_epicea_accounts do |file, w|
  rows = CSV.read(file, headers: true, encoding: "cp1252", col_sep: ";")
  w.count = rows.count
  rows.each do |row|
    # puts row.inspect
    w.check_point
  end
end
