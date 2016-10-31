module Ekylibre
  class EntitiesExchanger < ActiveExchanger::Base
    # Create or updates entities
    def import
      rows = CSV.read(file, headers: true)
      w.count = rows.size
      country_preference = Preference[:country]

      rows.each do |row|
        r = {
          first_name: row[0].blank? ? '' : row[0].to_s,
          last_name: row[1].blank? ? '' : row[1].to_s,
          nature: (%w(person contact sir madam doctor professor sir_and_madam).include?(row[2].to_s.downcase) ? :contact : :organization),
          client_account_number: row[3].blank? ? nil : row[3].to_s,
          supplier_account_number: row[4].blank? ? nil : row[4].to_s,
          address: row[5].to_s,
          postal_code: row[6].blank? ? nil : row[6].to_s,
          city: row[7].blank? ? nil : row[7].to_s,
          phone_number: row[8].blank? ? nil : row[8].to_s,
          fax_number: row[9].blank? ? nil : row[9].to_s,
          cell_number: row[10].blank? ? nil : row[10].to_s,
          link_nature: row[11].blank? ? :undefined : row[11].to_sym,
          link_entity_full_name: row[12].blank? ? nil : row[12].to_s,
          country: row[13].blank? ? country_preference : row[13].to_s.downcase,
          email: row[14].blank? ? nil : row[14].to_s,
          active: row[15].blank? ? false : true,
          prospect: row[16].blank? ? false : true,
          transporter: row[17].blank? ? false : true,
          siren_number: row[18].blank? ? nil : row[18].to_s.strip,
          vat_number: row[19].blank? ? nil : row[19].to_s,
          ape_number: row[20].blank? ? nil : row[20].to_s,
          number: row[21].blank? ? nil : row[21].to_s,
          supplier: row[22].blank? ? false : true
        }.to_struct

        person = Entity.find_by(number: r.number) if r.number
        person ||= Entity.where('first_name ILIKE ? AND last_name ILIKE ?', r.first_name.strip, r.last_name.strip).first
        if person
          person.update_attributes!(country: r.country) if person.country.blank?
        elsif
          person = Entity.new(
            first_name: r.first_name,
            last_name: r.last_name,
            number: r.number,
            nature: r.nature,
            country: r.country,
            active: r.active,
            prospect: r.prospect,
            transporter: r.transporter
          )
          person.save!
        end
        if r.client_account_number
          person.client = true
          person.client_account = Account.find_or_create_by_number(r.client_account_number, name: person.full_name)
          person.save!
        end
        if r.supplier_account_number
          person.supplier = true
          person.supplier_account = Account.find_or_create_by_number(r.supplier_account_number, name: person.full_name)
          person.save!
        end
        if r.supplier
          person.supplier = true
          person.save!
        end

        # Add SIREN, VAT or APE numbers if given
        unless r.siren_number.blank?
          if r.siren_number =~ /\A\d{9}\z/
            code = r.siren_number + '0001'
            person.siret_number = code + Luhn.control_digit(code).to_s
          else
            person.siret_number = r.siren_number
          end
          person.save!
        end

        if r.vat_number
          person.vat_number = r.vat_number
          person.save!
        end

        if r.ape_number
          person.activity_code = r.ape_number
          person.save!
        end

        # Add mail address if given
        if r.postal_code && r.city
          line_6 = r.postal_code + ' ' + r.city
          unless r.postal_code.blank? || r.city.blank? || person.mails.where('mail_line_6 ILIKE ?', line_6).where(mail_country: r.country).any?
            person.mails.create!(mail_line_4: r.address, mail_line_6: line_6, mail_country: r.country)
          end
        end

        # Add phone number if given
        unless r.phone_number.blank? || person.phones.where(coordinate: r.phone_number).any?
          person.phones.create!(coordinate: r.phone_number)
        end

        # Add cell phone number if given
        unless r.cell_number.blank? || person.mobiles.where(coordinate: r.cell_number).any?
          person.mobiles.create!(coordinate: r.cell_number)
        end

        # Add fax phone number if given
        unless r.fax_number.blank? || person.faxes.where(coordinate: r.fax_number).any?
          person.faxes.create!(coordinate: r.fax_number)
        end

        # Add email if given
        person.emails.create!(coordinate: r.email) unless r.email.blank?

        # Update account name
        natures = {
          management: :hierarchy,
          cooperation: :membership,
          work: :membership,
          association: :membership
        }
        if r.link_nature && r.link_entity_full_name
          entity_linked = Entity.where('full_name ILIKE ?', r.link_entity_full_name)
          nature = natures[r.link_nature] || r.link_nature
          person.link_to!(entity_linked.first, as: nature) if entity_linked.first && nature
        end

        w.check_point
      end
    end
  end
end
