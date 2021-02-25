# frozen_string_literal: true

module Ekylibre
  # Permits to import accounts from a CSV file with 3 columns:
  #  - Name
  #  - Family (from nomenclature ActivityFamily)
  #  - Cultivation variety (from nomenclature Variety)
  class AccountsExchanger < ActiveExchanger::Base
    category :accountancy
    vendor :ekylibre

    def check
      valid = true
      rows = CSV.read(file, headers: true).delete_if { |r| r[0].blank? }

      rows.each do |row|
        r = {
          number: row[0].to_s,
          name: (row[1].blank? ? nil : row[1].to_s.strip),
          nature: (row[2].blank? ? nil : row[2].to_sym)
        }.to_struct
      end

      valid
    end

    # Create or updates accounts
    def import
      rows = CSV.read(file, headers: true).delete_if { |r| r[0].blank? }
      w.count = rows.size

      rows.each do |row|
        r = {
          number: row[0].to_s.strip,
          name: (row[1].blank? ? nil : row[1].to_s),
          nature: (row[2].blank? ? nil : row[2].to_sym)
        }.to_struct

        # Exclude number dedicated to centralizing accounts
        next if r.number.strip.gsub(/0+\z/, '').in?(['401', '411'])

        # get usage from parent account or import account from nomenclature
        usages = Account.find_parent_usage(r.number)

        attributes = {
          name: r.name,
          number: r.number,
          usages: usages,
          already_existing: true
        }

        account = Account.find_by(number: r.number) || Account.find_or_initialize_by(number: r.number.ljust(Preference[:account_number_digits], '0'))
        if r.number.start_with?('401', '411')
          attributes[:centralizing_account_name] = r.number.start_with?('401') ? 'suppliers' : 'clients'
          attributes[:auxiliary_number] = r.number[3, r.number.length]
          attributes[:nature] = 'auxiliary'
        end
        account.attributes = attributes
        account.save!

        w.check_point
      end
    end
  end
end
