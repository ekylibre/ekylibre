# Create or updates journals from the Istea codes
Exchanges.add_importer :ekylibre_erp_entities do |file, w|

  rows = CSV.read(file, headers: true)
  w.count = rows.size

  rows.each do |row|
    r = OpenStruct.new(:first_name => row[0].blank? ? "" : row[0].to_s,
                       :last_name => row[1].blank? ? "" : row[1].to_s,
                       :nature => row[2].to_s.downcase,
                       :client_account_number => row[3].to_s,
                       :supplier_account_number => row[4].to_s,
                       :usages => row[5].to_s,
                       :address => row[6].to_s,
                       :postal_code => row[7].blank? ? nil : row[7].to_s,
                       :city => row[8].blank? ? nil : row[8].to_s,
                       country: "fr",
                       :phone_number => row[9].blank? ? nil : row[9].to_s,
                       :link_nature => row[10].blank? ? :undefined : row[10].to_sym,
                       :code => row[11].blank? ? nil : row[11].to_s.downcase
                       )

    klass = r.nature.camelcase.constantize
    unless person = klass.where("first_name ILIKE ? AND last_name ILIKE ?", r.first_name, r.last_name).first
      person = klass.new(first_name: r.first_name, last_name: r.last_name, nature: r.nature)
    end
    person.client = true
    person.client_account = Account.get(r.client_account_number, name: person.full_name)
    person.supplier = true
    person.supplier_account = Account.get(r.supplier_account_number, name: person.full_name)
    person.save!

    # Add mail address if given
    line_6 = r.postal_code + " " + r.city
    unless r.postal_code.blank? or r.city.blank? or person.mails.where("mail_line_6 ILIKE ?",  line_6).where(mail_country: r.country).any?
      person.mails.create!(mail_line_4: r.address, mail_line_6: line_6, mail_country: r.country)
    end

    # Add phone number if given
    unless r.phone_number.blank? or person.phones.where(coordinate: r.phone_number).any?
      person.phones.create!(coordinate: r.phone_number)
    end

    # Update account name
    if r.link_nature
      if r.link_nature.to_s.downcase == "management"
        associate_account = Account.find_by(number: r.client_account_number)
        associate_account.name = person.full_name
        associate_account.usages = r.usages
        associate_account.save!
      end
      person.is_linked_to!(Entity.of_company, as: r.link_nature)
    end
    w.check_point
  end

end
