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
          name: (row[1].blank? ? nil : row[1].to_s.strip),
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

      rows.each_with_index do |row, index|
        line_number = index + 2
        r = {
          number: row[0].to_s.strip.gsub(/0+\z/, ''),
          name: (row[1].blank? ? nil : row[1].to_s),
          nature: (row[2].blank? ? nil : row[2].to_sym)
        }.to_struct

        # puts "line : #{line_number} - number : #{r.number}".inspect.red

        # get usage from parent account or import account from nomenclature
        usages = Account.find_parent_usage(r.number)

        attributes = {
          name: r.name,
          number: r.number,
          usages: usages
        }

        account = Account.find_or_initialize_by(number: r.number)
        account.attributes = attributes
        account.save!

        # puts "line : #{line_number} - account created/updated : #{account.name}".inspect.green

        w.check_point
      end
    end
  end
end
