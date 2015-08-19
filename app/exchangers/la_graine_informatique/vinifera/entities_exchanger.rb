# coding: utf-8
class LaGraineInformatique::Vinifera::EntitiesExchanger < ActiveExchanger::Base
  
  def import
    
    # Unzip file
    dir = w.tmp_dir
    Zip::File.open(file) do |zile|
      zile.each do |entry|
        entry.extract(dir.join(entry.name))
      end
    end
    
    h_transcode = {}.with_indifferent_access
    
    custom_file = dir.join('custom_choices.csv')
    if custom_file.exist?
      CSV.foreach(custom_file, headers: true) do |row|
        r = {
        column_name: row[0].blank? ? '' : row[0].to_s,
        column_customized_type: row[1].blank? ? '' : row[1].to_sym,
        column_nature: row[2].blank? ? '' : row[2].to_sym,
        choices_file: row[3].blank? ? '' : row[3].to_s
      }.to_struct
        # get list for custom_field : 'vinifera_type_client'
        column_values = []
        path = dir.join(r.choices_file)
        if path.exist?
          CSV.foreach(path, headers: true) do |under_row|
            h_transcode[under_row[0]] = under_row[1].to_s.downcase if under_row[1]
            column_values << under_row[1].to_s.downcase if under_row[1]
          end
          cf = create_custom_field(r.column_name, r.column_nature, r.column_customized_type, column_values)
          w.info "#{cf.name} with column : #{cf.column_name} have been created" if cf
        else
          w.warn "No path found"
        end
      end
    end
    

    file = dir.join('entities.csv')
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
    # 10 PHONE 2
    # 11 CONTACT NAME
    # 12 TYPE CLIENT / client_types_transcode 
    # 33 ORIGIN (Transcode) - col 1 perso 
    # 34 CLIENT QUALITY (Transcode) - col 2 perso
    # 35 - - col 3 perso
    # 36 - col 4 perso
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
        client_types: row[12].blank? ? nil : row[12].to_s,
        price_types: row[13].blank? ? nil : row[13].to_s,
        client_origins: row[33].blank? ? nil : row[33].to_s,
        client_qualities: row[34].blank? ? nil : row[34].to_s,
        client_evolutions: row[36].blank? ? nil : row[36].to_s,
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
          r.title = expr.upcase
          r.last_name = r.full_name.gsub(/^#{expr}/i, '').strip
          break
        end
      end

      if person = Entity.where('full_name ILIKE ?', r.full_name.strip).first
        person.update_attributes!(country: r.country) if person.country.blank?
      elsif
        person = Entity.new(number: r.number,
                            title: r.title,
                            last_name: r.last_name,
                            full_name: r.full_name,
                            country: r.country,
                            nature: nature,
                            description: r.number
                           )
        person.save!
      end
      
      if r.client_types
       if r.client_types == "X" || r.client_types == "Y" || r.client_types == "Z"
         account_number = 412
       else
         account_number = 411
       end
       person.client = true
       person.client_account = Account.get(account_number, name: person.full_name)
       person.save!
      end
      
      if r.client_types
        if value = h_transcode[r.client_types]
          person['_vinifera_type_client'] = value
          person.save!
        end
      end
      
      if r.price_types
        if value = h_transcode[r.price_types]
          person['_vinifera_type_tarif'] = value
          person.save!
        end
      end
      
      if r.client_origins
        if value = h_transcode[r.client_origins]
          person['_vinifera_origine_client'] = value
          person.save!
        end
      end
      
      if r.client_qualities
        if value = h_transcode[r.client_qualities]
          person['_vinifera_qualite_client'] = value
          person.save!
        end
      end
      
      if r.client_evolutions
        if value = h_transcode[r.client_evolutions]
          person['_vinifera_evolution_client'] = value
          person.save!
        end
      end
      
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
  
  private
  
  def create_custom_field(column_name, column_nature, column_customized_type, values = [])
    # create custom field if not exist
    unless cf = CustomField.find_by_name(column_name)
      # create custom field
      cf = CustomField.create!(name: column_name, customized_type: column_customized_type, nature: column_nature)
      # create custom field choice if nature is choice
      if cf && column_nature == :choice  && values.any?
        for value in values
          cf.choices.create!(name: value)
        end
      end
    end
    return cf
  end
  
end
