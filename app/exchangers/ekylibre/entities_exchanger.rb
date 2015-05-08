class Ekylibre::EntitiesExchanger < ActiveExchanger::Base

  # Create or updates entities
  def import
    rows = CSV.read(file, headers: true)
    w.count = rows.size
    country_preference = Preference[:country]

    rows.each do |row|
      r = {
        :first_name => row[0].blank? ? "" : row[0].to_s,
        :last_name => row[1].blank? ? "" : row[1].to_s,
        :nature => row[2].to_s.downcase,
        :client_account_number => row[3].blank? ? nil : row[3].to_s,
        :supplier_account_number => row[4].blank? ? nil : row[4].to_s,
        :address => row[5].to_s,
        :postal_code => row[6].blank? ? nil : row[6].to_s,
        :city => row[7].blank? ? nil : row[7].to_s,
        :phone_number => row[8].blank? ? nil : row[8].to_s,
        :fax_number => row[9].blank? ? nil : row[9].to_s,
        :cell_number => row[10].blank? ? nil : row[10].to_s,
        :link_nature => row[11].blank? ? :undefined : row[11].to_sym,
        :link_entity_full_name => row[12].blank? ? nil : row[12].to_s,
        :country => row[13].blank? ? country_preference : row[13].to_s.downcase,
        :email => row[14].blank? ? nil : row[14].to_s,
        :active => row[15].blank? ? false : true,
        :prospect => row[16].blank? ? false : true,
        :transporter => row[17].blank? ? false : true,
        :siren_number => row[18].blank? ? nil : row[18].to_s,
        :vat_number => row[19].blank? ? nil : row[19].to_s,
        :ape_number => row[20].blank? ? nil : row[20].to_s
      }.to_struct

      klass = r.nature.camelcase.constantize
      if person = klass.where("first_name ILIKE ? AND last_name ILIKE ?", r.first_name.strip, r.last_name.strip).first
        person.update_attributes!(country: r.country) if person.country.blank?
      elsif
        person = klass.new(first_name: r.first_name,
                           last_name: r.last_name,
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
        person.client_account = Account.get(r.client_account_number, name: person.full_name)
        person.save!
      end
      if r.supplier_account_number
        person.supplier = true
        person.supplier_account = Account.get(r.supplier_account_number, name: person.full_name)
        person.save!
      end

      # Add SIREN, VAT or APE numbers if given
      if r.siren_number
        person.siren = r.siren_number
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
      line_6 = r.postal_code + " " + r.city
      unless r.postal_code.blank? or r.city.blank? or person.mails.where("mail_line_6 ILIKE ?",  line_6).where(mail_country: r.country).any?
        person.mails.create!(mail_line_4: r.address, mail_line_6: line_6, mail_country: r.country)
      end

      # Add phone number if given
      unless r.phone_number.blank? or person.phones.where(coordinate: r.phone_number).any?
        person.phones.create!(coordinate: r.phone_number)
      end

      # Add cell phone number if given
      unless r.cell_number.blank? or person.mobiles.where(coordinate: r.cell_number).any?
        person.mobiles.create!(coordinate: r.cell_number)
      end

      # Add fax phone number if given
      unless r.fax_number.blank? or person.faxes.where(coordinate: r.fax_number).any?
        person.faxes.create!(coordinate: r.fax_number)
      end

      # Add email if given
      unless r.email.blank?
        person.emails.create!(coordinate: r.email)
      end

      # Update account name
      if r.link_nature and r.link_entity_full_name
        entity_linked = Entity.where("full_name ILIKE ?", r.link_entity_full_name)
        person.is_linked_to!(entity_linked.first, as: r.link_nature) if entity_linked
      end

      w.check_point
    end
  end

end
