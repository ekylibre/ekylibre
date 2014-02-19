# -*- coding: utf-8 -*-
load_data :products do |loader|

  unless building_division = BuildingDivision.first
    raise "Need a BuildingDivision"
  end


  file = loader.path("alamano", "equipments.csv")
  if file.exist?
    loader.count :equipments do |w|
      #############################################################################

      CSV.foreach(file, :encoding => "UTF-8", :col_sep => ",", :headers => true, :quote_char => "'") do |row|
        r = OpenStruct.new(:name => row[0].blank? ? nil : row[0].to_s,
                           :variant_reference_name => row[1].downcase.to_sym,
                           :work_number => row[2].blank? ? nil : row[2].to_s,
                           :born_at => (row[3].blank? ? Date.civil(2000, 2, 2) : row[3]).to_datetime,
                           :brand => row[4].blank? ? nil : row[4].to_s,
                           :model => row[5].blank? ? nil : row[5].to_s,
                           :external => !row[6].blank?,
                           :indicators => row[7].blank? ? {} : row[7].to_s.strip.split(/[[:space:]]*\;[[:space:]]*/).collect{|i| i.split(/[[:space:]]*\:[[:space:]]*/)}.inject({}) { |h, i|
                             h[i.first.strip.downcase.to_sym] = i.second
                             h
                           },
                           :owner_name => row[6].blank? ? nil : row[6].to_s,
                           :notes => row[8].blank? ? nil : row[8].to_s,
                           :unit_price => row[9].blank? ? nil : row[9].to_d,
                           :price_indicator => row[10].blank? ? nil : row[10].to_sym
                           )

        # find or import from variant reference_nameclature the correct ProductNatureVariant
        variant = ProductNatureVariant.find_by(:reference_name => r.variant_reference_name) || ProductNatureVariant.import_from_nomenclature(r.variant_reference_name)
        pmodel = variant.nature.matching_model

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

        # create the equipment
        equipment = pmodel.create!(:variant_id => variant.id, :name => r.name, :initial_born_at => r.born_at, :initial_owner => owner, :default_storage => building_division, :work_number => r.work_number )

        # create indicators linked to equipment
        for indicator, value in r.indicators
          equipment.read!(indicator, value, at: r.born_at, force: true)
        end

        w.check_point
      end

    end
  end


  file = loader.path("alamano", "matters.csv")
  if file.exist?

    loader.count :matters do |w|
      #############################################################################

      CSV.foreach(file, :encoding => "UTF-8", :col_sep => ",", :headers => true, :quote_char => "'") do |row|
        r = OpenStruct.new(:name => row[0].blank? ? nil : row[0].to_s,
                           :variant_reference_name => row[1].downcase.to_sym,
                           :work_number => row[2].blank? ? nil : row[2].to_s,
                           :born_at => (row[3].blank? ? (Date.today - 200) : row[3]).to_datetime,
                           :variety => row[4].blank? ? nil : row[4].to_s,
                           :derivative_of => row[5].blank? ? nil : row[5].to_s,
                           :external => !row[6].blank?,
                           :indicators => row[7].blank? ? {} : row[7].to_s.strip.split(/[[:space:]]*\;[[:space:]]*/).collect{|i| i.split(/[[:space:]]*\:[[:space:]]*/)}.inject({}) { |h, i|
                             h[i.first.strip.downcase.to_sym] = i.second
                             h
                           },
                           :owner_name => row[6].blank? ? nil : row[6].to_s,
                           :notes => row[8].blank? ? nil : row[8].to_s,
                           :unit_price => row[9].blank? ? nil : row[9].to_d
                           )

        # find or import from variant reference_nameclature the correct ProductNatureVariant
        variant = ProductNatureVariant.find_by(:reference_name => r.variant_reference_name) || ProductNatureVariant.import_from_nomenclature(r.variant_reference_name)
        pmodel = variant.nature.matching_model

        # create a price
        if r.unit_price
          variant.prices.create!(catalog_id: Catalog.where(usage: :cost).first.id, all_taxes_included: false, amount: r.unit_price, currency: "EUR")
        end

        # create the owner if not exist
        if r.external == true
          owner = Entity.where(:last_name => r.owner_name.to_s).first
          owner ||= Entity.create!(:born_at => Date.today, :last_name => r.owner_name.to_s, :currency => "EUR", :language => "fra", :nature => "company")
        else
          owner = Entity.of_company
        end

        # create the product
        product = pmodel.create!(:variant_id => variant.id, :work_number => r.work_number,
                                 :name => r.name, :initial_born_at => r.born_at, :initial_owner => owner, :variety => r.variety, :derivative_of => r.derivative_of, :default_storage => building_division)

        # create indicators linked to equipment
        for indicator, value in r.indicators
          product.read!(indicator, value, at: r.born_at, force: true)
        end

        w.check_point
      end
    end

  end

end
