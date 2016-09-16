module Ekylibre
  # Permits to import accounts from a CSV file with 3 columns:
  #  - Name
  #  - Family (from nomenclature ActivityFamily)
  #  - Cultivation variety (from nomenclature Variety)
  class AccountsExchanger < ActiveExchanger::Base
    def check
      valid = true
      rows = CSV.read(file, headers: true).delete_if { |r| r[0].blank? }
      w.count = rows.size
      rows.each do |row|
        r = {
          number: row[0].to_s.strip.gsub(/0+\z/, ''),
          name: (row[1].blank? ? nil : row[1].to_s),
          nature: (row[2].blank? ? nil : row[2].to_sym)
        }.to_struct

        w.check_point
      end
      valid
    end

    # Create or updates accounts
    def import
      rows = CSV.read(file, headers: true).delete_if { |r| r[0].blank? }
      w.count = rows.size

      rows.each do |row|
        r = {
          number: row[0].to_s.strip.gsub(/0+\z/, ''),
          name: (row[1].blank? ? nil : row[1].to_s),
          nature: (row[2].blank? ? nil : row[2].to_sym)
        }.to_struct

        parent_accounts = nil
        items = nil

        max = r.number.size - 1
        # get usages of nearest existing account by number
        (0..max).to_a.reverse.each do |i|
          number = r.number[0, i]
          puts number.inspect.yellow
          items = Nomen::Account.where(fr_pcga: number)
          parent_accounts = Account.find_with_regexp(number)
          break if parent_accounts.any?
        end

        if parent_accounts && parent_accounts.any?
          usages = parent_accounts.first.usages
        elsif items.any?
          a = Account.find_or_import_from_nomenclature(items.first.usages)
          usages = a.usages
        else
          usages = nil
        end

        attributes = {
          name: r.name,
          number: r.number,
          usages: usages
        }

        account = Account.find_or_initialize_by(number: r.number)
        account.attributes = attributes
        account.save!

        w.check_point
      end
    end
  end
end
