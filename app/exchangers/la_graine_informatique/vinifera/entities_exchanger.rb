# coding: utf-8
class LaGraineInformatique::Vinifera::EntitiesExchanger < ActiveExchanger::Base
  def import
    rows = CSV.read(file, headers: true, encoding: 'cp1252', col_sep: ';')
    w.count = rows.count

    # FILE STRUCTURE
    # 0 CATEGORY
    # 1 CODE
    # 2 FULL NAME
    # 3,4,5 ADRESSE
    # 6 POSTAL CODE AND TOWN
    # 7 POSTAL CODE
    # 8 PHONE
    # 9 FAX
    #  10 PHONE 2
    # 11 CONTACT NAME
    # 33 ORIGIN (Transcode)
    # 34 CLIENT QUALITY (Transcode)
    # 59 NOTE
    # 67 EMAIL
    # 68 DATE CREATION

    country_preference = Preference[:country]

    rows.each do |row|
      r = {
        number: row[1].blank? ? '' : row[1].to_s,
        full_name: row[2].blank? ? '' : row[2].to_s.strip,
        last_name: row[2].blank? ? '' : row[2].to_s.strip,
        type: 'Entity',
        address_line_1: row[3].blank? ? nil : row[3].to_s,
        address_line_2: row[4].blank? ? nil : row[4].to_s,
        address_line_3: row[5].blank? ? nil : row[5].to_s,
        postal_code_city: row[6].blank? ? nil : row[6].to_s,
        phone_number: row[8].blank? ? nil : row[8].to_s,
        fax_number: row[9].blank? ? nil : row[9].to_s,
        cell_number: row[10].blank? ? nil : row[10].to_s,
        country: row[13].blank? ? country_preference : row[13].to_s.downcase,
        email: row[67].blank? ? nil : row[67].to_s,
        description: row[59].blank? ? nil : row[59].to_s,
        active: row[15].blank? ? false : true,
        prospect: row[16].blank? ? false : true
      }.to_struct

      nature = :organization
      { 'madame et monsieur' => :contact,
        'monsieur et madame' => :contact,
        'monsieur' => :contact,
        'madame' => :contact
      }.each do |expr, name|
        if r.full_name =~ /^#{expr}/i
          nature = name
          r.last_name = r.full_name.gsub(/^#{expr}/i, '').strip
          break
        end
      end

      if person = Entity.where('full_name ILIKE ?', r.full_name.strip).first
        person.update_attributes!(country: r.country) if person.country.blank?
      elsif
        person = Entity.new(number: r.number,
                            last_name: r.full_name,
                            full_name: r.full_name,
                            country: r.country,
                            nature: nature,
                            description: r.number
                           )
        person.save!
      end
      # if r.client_account_number
      #  person.client = true
      #  person.client_account = Account.get(r.client_account_number, name: person.full_name)
      #  person.save!
      # end

      # Add mail address if given
      mail_attributes = {}
      mail_attributes.store(:mail_line_3, r.address_line_1) if r.address_line_1
      mail_attributes.store(:mail_line_4, r.address_line_2) if r.address_line_2
      mail_attributes.store(:mail_line_5, r.address_line_3) if r.address_line_3
      mail_attributes.store(:mail_line_6, r.postal_code_city) if r.postal_code_city
      mail_attributes.store(:mail_country, r.country) if r.country
      unless r.postal_code_city.blank? || person.mails.where('mail_line_6 ILIKE ?', r.postal_code_city).where(mail_country: r.country).any?
        person.mails.create!(mail_attributes)
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

      w.check_point
    end
  end
end
