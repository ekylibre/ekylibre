# Create or updates equipments
Exchanges.add_importer :ekylibre_equipments do |file, w|

  if building_division = BuildingDivision.first

    rows = CSV.read(file, headers: true).delete_if{|r| r[0].blank?}
    w.count = rows.size

    rows.each do |row|
      r = {
        :name => row[0].blank? ? nil : row[0].to_s,
        :variant_reference_name => row[1].blank? ? nil : row[1].downcase.to_sym,
        :work_number => row[2].blank? ? nil : row[2].to_s,
        :place_code => row[3].blank? ? nil : row[3].to_s,
        :born_at => (row[4].blank? ? Date.civil(2000, 2, 2) : row[4]).to_datetime,
        :brand => row[5].blank? ? nil : row[5].to_s,
        :model => row[6].blank? ? nil : row[6].to_s,
        :external => !row[7].blank?,
        :owner_name => row[7].blank? ? nil : row[7].to_s,
        :indicators => row[8].blank? ? {} : row[8].to_s.strip.split(/[[:space:]]*\;[[:space:]]*/).collect{|i| i.split(/[[:space:]]*\:[[:space:]]*/)}.inject({}) { |h, i|
          h[i.first.strip.downcase.to_sym] = i.second
          h
        },
        :notes => row[9].blank? ? nil : row[9].to_s,
        :unit_pretax_amount => row[10].blank? ? nil : row[10].to_d,
        :price_indicator => row[11].blank? ? nil : row[11].to_sym
      }.to_struct

      if r.variant_reference_name
        # find or import from variant reference_nameclature the correct ProductNatureVariant
        variant = ProductNatureVariant.import_from_nomenclature(r.variant_reference_name)
        pmodel = variant.matching_model

        # create a price
        if r.unit_pretax_amount and catalog = Catalog.where(usage: :cost).first and variant.catalog_items.where(catalog_id: catalog.id).empty?
          variant.catalog_items.create!(catalog: catalog, all_taxes_included: false, amount: r.unit_pretax_amount, currency: "EUR") # , indicator_name: r.price_indicator.to_s
        end

        # create the owner if not exist
        if r.external == true
          owner = Entity.where(:last_name => r.owner_name.to_s).first
          owner ||= Entity.create!(:born_at => Date.today, :last_name => r.owner_name.to_s, :currency => Preference[:currency], :language => Preference[:language], :nature => "company")
        else
          owner = Entity.of_company
        end

        container = nil
        unless container = Product.find_by_work_number(r.place_code)
          container = building_division
        end

        # create the equipment
        equipment = pmodel.create!(:variant_id => variant.id, :name => r.name, :initial_born_at => r.born_at, :initial_owner => owner, :initial_container => container, :default_storage => container, :work_number => r.work_number )

        # create indicators linked to equipment
        for indicator, value in r.indicators
          equipment.read!(indicator, value, at: r.born_at, force: true)
        end

        if container = Product.find_by_work_number(r.place_code)
          # container.add(zone, born_at)
          equipment.update_attributes(initial_container: container)
          equipment.save!
        end

        # attach georeading if exist for equipment
        if equipment
          if georeading = Georeading.find_by(number: r.work_number, nature: :polygon)
            equipment.read!(:shape, georeading.content, at: r.born_at, force: true)
          end
          if georeading = Georeading.find_by(number: r.work_number, nature: :point)
            equipment.read!(:geolocation, georeading.content, at: r.born_at, force: true)
          end
        end

        w.check_point
      else
        w.warn "Need a Variant for #{r.name}"
      end
    end

  else
    w.warn "Need a BuildingDivision"
  end

end
