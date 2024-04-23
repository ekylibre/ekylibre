# frozen_string_literal: true

module Ekylibre
  class AssociatesExchanger < ActiveExchanger::Base
    category :accountancy
    vendor :ekylibre

    def check
      valid = true
      rows = CSV.read(file, headers: true).delete_if { |r| r[0].blank? }
      w.count = rows.size
      rows.each do |row|
        r = {
          first_name: row[0].blank? ? nil : row[0].to_s,
          last_name: row[1].blank? ? nil : row[1].to_s,
          started_on: row[2].blank? ? nil : Date.parse(row[2].to_s),
          nature: (%w[owner usufructuary bare_owner].include?(row[3].to_s.downcase) ? row[3].to_s.downcase : 'owner'),
          associate_account_number: row[4].blank? ? nil : row[4].to_s,
          share_quantity: row[5].blank? ? nil : row[5].to_i,
          share_unit_amount: row[6].blank? ? nil : row[6].tr(',', '.').to_d
        }.to_struct
        valid = false if r.last_name.nil?
        valid = false if r.started_on.nil?
        valid = false if r.share_quantity.nil?
        valid = false if r.share_unit_amount.nil?
        if r.associate_account_number.present? && r.associate_account_number.start_with?("4551")
          valid = true
        else
          valid = false
        end
        w.check_point
      end
      valid
    end

    # Create or updates associates
    def import
      rows = CSV.read(file, headers: true)
      w.count = rows.size
      country_preference = Preference[:country]

      rows.each do |row|
        r = {
          first_name: row[0].blank? ? '' : row[0].to_s.strip,
          last_name: row[1].blank? ? '' : row[1].to_s.strip,
          started_on: row[2].blank? ? nil : Date.parse(row[2].to_s),
          nature: (%w[owner usufructuary bare_owner].include?(row[3].to_s.downcase) ? row[3].to_s.downcase : 'owner'),
          associate_account_number: row[4].blank? ? nil : row[4].to_s.strip,
          share_quantity: row[5].blank? ? nil : row[5].to_i,
          share_unit_amount: row[6].blank? ? nil : row[6].tr(',', '.').to_d
        }.to_struct

        # find or create entity
        if r.first_name.present? && r.last_name.present?
          person = Entity.where(nature: 'contact').where('first_name ILIKE ? AND last_name ILIKE ?', r.first_name, r.last_name).first
          person ||= Entity.new(
            first_name: r.first_name,
            last_name: r.last_name,
            nature: :contact,
            country: 'fra',
            active: true
          )
        elsif r.last_name.present?
          person = Entity.where(nature: 'organization').where('full_name ILIKE ?', r.last_name).first
          person ||= Entity.new(
            last_name: r.last_name,
            nature: :organization,
            country: 'fra',
            active: true
          )
        end

        # find or create associate account
        if r.associate_account_number.present? && person.present?
          account = Account.find_or_create_by_number(r.associate_account_number, name: person.full_name)
        end

        # find or create associate
        if account.present? && person.present?
          unless Associate.find_by(entity: person)
            Associate.create!(
              entity: person,
              associate_nature: r.nature.to_sym,
              associate_account: account,
              started_on: r.started_on,
              share_quantity: r.share_quantity,
              share_unit_amount: r.share_unit_amount
            )
          end
        end

        w.check_point
      end
    end
  end
end
