# Create or updates equipments
Exchanges.add_importer :ekylibre_workers do |file, w|

  if building_division = BuildingDivision.first

    rows = CSV.read(file, headers: true).delete_if{|r| r[0].blank?}
    w.count = rows.size

    rows.each do |row|
      r = {
        name: row[0].blank? ? nil : row[0].to_s,
        first_name: row[1],
        last_name: row[2],
        variant_reference_name: row[3].downcase.to_sym,
        work_number: row[4],
        place_code: row[5],
        born_at: (row[6].blank? ? Date.civil(1980, 2, 2) : Date.new(*(row[6].split('-').map(&:to_i)))).to_datetime,
        notes: row[7].to_s,
        unit_pretax_amount: row[8].blank? ? nil : row[8].to_d,
        price_indicator: row[9].blank? ? nil : row[9].to_sym,
        email: row[10]
      }.to_struct

      # Find or import from variant reference_name the correct ProductNatureVariant
      unless variant = ProductNatureVariant.find_by(reference_name: r.variant_reference_name)
        variant = ProductNatureVariant.import_from_nomenclature(r.variant_reference_name)
      end
      pmodel = variant.matching_model

      # create a price
      if r.unit_pretax_amount and catalog = Catalog.where(usage: :cost).first and variant.catalog_items.where(catalog_id: catalog.id).empty?
        variant.catalog_items.create!(catalog: catalog, all_taxes_included: false, amount: r.unit_pretax_amount, currency: "EUR") # , indicator_name: r.price_indicator.to_s
      end

      # create the owner if not exist
      unless person = Person.find_by(first_name: r.first_name, last_name: r.last_name)
        person = Person.create!(first_name: r.first_name, last_name: r.last_name, born_at: r.born_at)
      end

      # create the user
      if person and r.email.present? and !person.user
        unless user = User.find_by(email: r.email)
          password = User.generate_password(100, :hard)
          user = User.create!(first_name: r.first_name, last_name: r.last_name, email: email, password: password, password_confirmation: password, language: Preference[:language], role: Role.order(:id).first)
        end
        unless user.person
          user.person = person
          user.save!
        end
      end


      owner = Entity.of_company

      unless container = Product.find_by(work_number: r.place_code)
        container = building_division
      end

      # create the worker
      worker = pmodel.create!(variant: variant, name: r.name, initial_born_at: r.born_at, initial_owner: owner, default_storage: container, work_number: r.work_number, person: person)

      # attach georeading if exist for worker
      if worker
        if georeading = Georeading.find_by(number: r.work_number, nature: :point)
          worker.read!(:geolocation, georeading.content, at: r.born_at, force: true)
        end
      end
      

      w.check_point
    end

  else
    w.warn "Need a BuildingDivision"
  end

end
