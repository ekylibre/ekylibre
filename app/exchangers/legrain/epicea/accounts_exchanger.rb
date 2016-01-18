class Legrain::Epicea::AccountsExchanger < ActiveExchanger::Base
  def import
    rows = CSV.read(file, headers: true, encoding: 'cp1252', col_sep: ';', quote_char: "'")
    w.count = rows.count

    # asociate usage to its account number
    usage_by_account_number = {}
    Nomen::Account.all.each do |usage|
      usage_by_account_number[Nomen::Account[usage].fr_pcga] = usage
    end

    rows.each do |row|
      account_number = row[0].to_s
      label = row[1].to_s.tr('"', "'")
      usage = usage_by_account_number[account_number]
      if usage.present?
        account = Account.find_or_import_from_nomenclature(usage)
      else
        upper_account_number = account_number.chop
        while upper_account_number.present?
          usage = usage_by_account_number[upper_account_number]
          break if usage.present?
          upper_account_number.chop!
        end
        account = Account.create(number: account_number, name: label, usages: usage)
        account.save
      end
      w.check_point
    end
  end
end
