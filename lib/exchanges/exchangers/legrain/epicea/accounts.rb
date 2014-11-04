Exchanges.add_importer :legrain_epicea_accounts do |file, w|
  rows = CSV.read(file, headers: true, encoding: "cp1252", col_sep: ";")
  w.count = rows.count

  # asociate usage to its account number
  usage_by_account_number = {}
  Nomen::Accounts.all.each do |usage|
    usage_by_account_number[Nomen::Accounts[usage].fr_pcga] = usage
  end

  rows.each do |row|
    usage = usage_by_account_number[row[0]]
    if usage.present?
      account = Account.find_or_create_in_chart(usage)
    end
    w.check_point
  end
end
