module LaGraineInformatique
  module Vinifera
    class EntitiesExchanger < ActiveExchanger::Base
      def import
        # Unzip file
        dir = w.tmp_dir
        Zip::File.open(file) do |zile|
          zile.each do |entry|
            entry.extract(dir.join(entry.name))
          end
        end

        custom_file = dir.join('custom_fields.csv')
        custom_fields = create_custom_fields(custom_file, dir)

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
            client_type: row[12].blank? ? nil : row[12].to_s,
            client_price_type: row[13].blank? ? nil : row[13].to_s,
            client_origin: row[33].blank? ? nil : row[33].to_s,
            client_quality: row[34].blank? ? nil : row[34].to_s,
            client_evolution: row[36].blank? ? nil : row[36].to_s,
            email: row[67].blank? ? nil : row[67].to_s,
            description: row[59].blank? ? nil : row[59].to_s,
            active: row[15].blank? ? false : true,
            prospect: row[16].blank? ? false : true
          }.to_struct

          nature = :organization
          { 'madame et monsieur' => :contact,
            'monsieur et madame' => :contact,
            'monsieur' => :contact,
            'madame' => :contact }.each do |expr, name|
            next unless r.full_name =~ /^#{expr}/i
            nature = name
            r.title = expr.upcase
            r.last_name = r.full_name.gsub(/^#{expr}/i, '').strip
            break
          end

          if person = Entity.where('full_name ILIKE ?', r.full_name.strip).first
            person.country = r.country if person.country.blank?
          elsif
            person = Entity.new(
              number: r.number,
              title: r.title,
              last_name: r.last_name,
              full_name: r.full_name,
              country: r.country,
              nature: nature,
              description: r.number
            )
          end

          if r.client_type
            account_number = if r.client_type == 'X' || r.client_type == 'Y' || r.client_type == 'Z'
                               412
                             else
                               411
                             end
            person.client = true
            person.client_account = Account.find_or_initialize_by(number: account_number)
            person.client_account.name ||= person.full_name
            person.client_account.save!
          end

          custom_fields.each do |cf|
            val = r.send(cf.name).to_s.strip.gsub(/[[:space:]\_]+/, '-')
            person.set_custom_value(cf.field, val) if val.present?
          end

          person.save!

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
          person.emails.create!(coordinate: r.email) if r.email.present?

          w.check_point
        end
      end

      private

      def create_custom_fields(file, dir)
        list = []
        return list unless file.exist?
        CSV.foreach(file, headers: true) do |row|
          r = {
            name: row[0].to_s,
            label: row[1].to_s,
            nature: row[2].blank? ? :string : row[2].to_sym,
            customized_type: 'Entity',
            choices: {}
          }.to_struct
          path = dir.join("#{r.name.pluralize}_transcode.csv")
          if path.exist?
            CSV.foreach(path, headers: true) do |under_row|
              r.choices[under_row[0].strip.gsub(/[[:space:]\_]+/, '-')] = under_row[1].strip
            end
          elsif nature == :choice
            w.warn 'No path found for choices'
          end
          r.field = create_custom_field(r.label, r.customized_type,
                                        choices: r.choices, nature: r.nature, column_name: r.name)
          list << r
        end
        list
      end

      def create_custom_field(name, customized_type, options = {})
        # create custom field if not exist
        unless cf = CustomField.find_by(name: name)
          # create custom field
          cf = CustomField.create!(name: name, customized_type: customized_type,
                                   nature: options[:nature] || :string,
                                   column_name: options[:column_name])
          # create custom field choice if nature is choice
          if cf.choice? && options[:choices]
            options[:choices].each do |value, label|
              cf.choices.create!(name: label, value: value)
            end
          end
        end
        cf
      end
    end
  end
end
