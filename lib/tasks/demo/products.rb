# -*- coding: utf-8 -*-
demo :products do


  Ekylibre::fixturize :equipments do |w|
    #############################################################################

    file = Rails.root.join("test", "fixtures", "files", "equipments_list.csv")
    CSV.foreach(file, :encoding => "UTF-8", :col_sep => ",", :headers => true, :quote_char => "'") do |row|
      r = OpenStruct.new(:name => row[0].blank? ? nil : row[0].to_s,
                         :nature_nomen => row[1].downcase.to_sym,
                         :variant => row[2].blank? ? nil : row[2],
                         :born_at => row[3].blank? ? Date.today : row[3],
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
                         :indicator_price => row[10].blank? ? nil : row[10].to_sym
                         )

      # find or import from nomenclature the correct ProductNature
      product_nature = ProductNature.find_by(:nomen => r.nature_nomen) || ProductNature.import_from_nomenclature(r.nature_nomen)
      variant = product_nature.default_variant
      
      # create a price
      if r.unit_price
        variant.prices.create!(catalog_id: Catalog.where(usage: :cost).first.id, all_taxes_included: false, amount: r.unit_price, currency: "EUR", indicator: r.indicator_price.to_s)
      end
      
      # create the owner if not exist
      if r.external == true
        owner = Entity.where(:last_name => r.owner_name.to_s).first
        owner ||= Entity.create!(:born_on => Date.today, :last_name => r.owner_name.to_s, :currency => "EUR", :language => "fra", :nature => "company")
      else
        owner = Entity.of_company
      end

      # create the equipment
      equipment = Equipment.create!(:variant_id => variant.id, :name => r.name, :born_at => r.born_at, :initial_owner => owner )

      # create indicators linked to equipment
      for indicator, value in r.indicators
        equipment.is_measured!(indicator, value)
      end

      w.check_point
    end


  end

  Ekylibre::fixturize :matters do |w|
    #############################################################################

    file = Rails.root.join("test", "fixtures", "files", "matters_list.csv")
    CSV.foreach(file, :encoding => "UTF-8", :col_sep => ",", :headers => true, :quote_char => "'") do |row|
      r = OpenStruct.new(:name => row[0].blank? ? nil : row[0].to_s,
                         :nature_nomen => row[1].downcase.to_sym,
                         :variant => row[2].blank? ? nil : row[2],
                         :born_at => row[3].blank? ? Date.today : row[3],
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

      # find or import from nomenclature the correct ProductNature
      product_nature = ProductNature.find_by(:nomen => r.nature_nomen) || ProductNature.import_from_nomenclature(r.nature_nomen)
      variant = product_nature.default_variant
      pmodel = product_nature.matching_model
      
      # create a price
      if r.unit_price
        variant.prices.create!(catalog_id: Catalog.where(usage: :cost).first.id, all_taxes_included: false, amount: r.unit_price, currency: "EUR")
      end
      
      # create the owner if not exist
      if r.external == true
        owner = Entity.where(:last_name => r.owner_name.to_s).first
        owner ||= Entity.create!(:born_on => Date.today, :last_name => r.owner_name.to_s, :currency => "EUR", :language => "fra", :nature => "company")
      else
        owner = Entity.of_company
      end

      # create the product
      product = pmodel.create!(:variant_id => variant.id,
                                    :name => r.name, :born_at => r.born_at, :initial_owner => owner, :variety => r.variety, :derivative_of => r.derivative_of )

      # create indicators linked to equipment
      for indicator, value in r.indicators
        product.is_measured!(indicator, value)
      end

      w.check_point
    end


  end

end
