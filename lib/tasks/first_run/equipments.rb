# -*- coding: utf-8 -*-
load_data :equipments do |loader|

  unless building_division = BuildingDivision.first
    raise "Need a BuildingDivision"
  end


  path = loader.path("alamano", "equipments.csv")
  if path.exist?
    loader.count :equipments do |w|
      #############################################################################

      CSV.foreach(path, headers: true) do |row|
        next if row[0].blank?
        r = OpenStruct.new(:name => row[0].blank? ? nil : row[0].to_s,
                           :variant_reference_name => row[1].downcase.to_sym,
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
                           :unit_price => row[10].blank? ? nil : row[10].to_d,
                           :price_indicator => row[11].blank? ? nil : row[11].to_sym
                           )

        # find or import from variant reference_nameclature the correct ProductNatureVariant
        variant = ProductNatureVariant.import_from_nomenclature(r.variant_reference_name)
        pmodel = variant.matching_model

        # create a price
        if r.unit_price
          variant.prices.create!(catalog: Catalog.where(usage: :cost).first, all_taxes_included: false, amount: r.unit_price, currency: "EUR", indicator_name: r.price_indicator.to_s)
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

        w.check_point
      end

    end
  end

  path = loader.path("alamano", "zones", "equipments.shp")
  if path.exist?
    loader.count :equipments_shapes do |w|
      #############################################################################
      RGeo::Shapefile::Reader.open(path.to_s, :srid => 4326) do |file|
        # puts "File contains #{file.num_records} records."
        file.each do |record|
          if zone = Product.find_by_work_number(record.attributes['number'])
            zone.read!(:shape, record.geometry, at: zone.born_at, force: true)
          end
          w.check_point
        end
      end
    end
  end


  path = loader.path("alamano", "workers.csv")
  if path.exist?
    loader.count :workers do |w|
      #############################################################################

      CSV.foreach(path, headers: true) do |row|
        # next if row[0].blank?
        r = OpenStruct.new(name: row[0].blank? ? nil : row[0].to_s,
                           first_name: row[1],
                           last_name: row[2],
                           variant_reference_name: row[3].downcase.to_sym,
                           work_number: row[4],
                           place_code: row[5],
                           born_at: (row[6].blank? ? Date.civil(1980, 2, 2) : Date.new(*(row[6].split('-').map(&:to_i)))).to_datetime,
                           notes: row[7].to_s,
                           unit_price: row[8].blank? ? nil : row[8].to_d,
                           price_indicator: row[9].blank? ? nil : row[9].to_sym,
                           email: row[10]
                           )

        # Find or import from variant reference_name the correct ProductNatureVariant
        unless variant = ProductNatureVariant.find_by(reference_name: r.variant_reference_name)
          variant = ProductNatureVariant.import_from_nomenclature(r.variant_reference_name)
        end
        pmodel = variant.matching_model

        # create a price
        if r.unit_price
          variant.prices.create!(catalog: Catalog.where(usage: :cost).first, all_taxes_included: false, amount: r.unit_price, currency: "EUR", indicator_name: r.price_indicator.to_s)
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

        w.check_point
      end

    end
  end

  path = loader.path("alamano", "zones", "initial_geolocations.shp")
  if path.exist?
    loader.count :initial_geolocations do |w|
      #############################################################################
      RGeo::Shapefile::Reader.open(path.to_s, :srid => 4326) do |file|
        # puts "File contains #{file.num_records} records."
        file.each do |record|
          if product = Product.find_by_work_number(record.attributes['number'])
            product.read!(:geolocation, record.geometry, at: product.born_at, force: true)
          end
          w.check_point
        end
      end
    end
  end

end
