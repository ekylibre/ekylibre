# -*- coding: utf-8 -*-
demo :buildings do

  standard_place_variant = ProductNatureVariant.import_from_nomenclature(:building)

  Ekylibre::fixturize :buildings do |w|
    #############################################################################
    # Import (from nomenclature) a default product_nature to place animal
    animal_place_variant = ProductNatureVariant.import_from_nomenclature(:animal_building)
    settlement_place_variant = ProductNatureVariant.import_from_nomenclature(:screed_building)
    office_place_variant = ProductNatureVariant.import_from_nomenclature(:office_building)
    born_at = Time.new(1995, 1, 1, 10, 0, 0, "+00:00")

    # TODO Localize or externalize localized data
    for building in [{variant_id: standard_place_variant.id,   name: "Bâtiment historique", :work_number => "B05", :identification_number => "STABULATION_05"},
                     {variant_id: settlement_place_variant.id, name: "Aire bétonnée", :work_number => "B06", :identification_number => "STABULATION_06"},
                     {variant_id: animal_place_variant.id,     name: "Stabulation principale", :work_number => "B07", :identification_number => "STABULATION_07"},
                     {variant_id: animal_place_variant.id,     name: "Bâtiment Taurillons Bois", :work_number => "B04", :identification_number => "BAT_TAURILLON"},
                     {variant_id: animal_place_variant.id,     name: "Bâtiment Bouquet en L Genisse", :work_number => "B03", :identification_number => "BAT_GEN"},
                     {variant_id: animal_place_variant.id,     name: "Poulailler 1 (côté Jardin)", :work_number => "B09", :identification_number => "BAT_POULAILLER_1"},
                     {variant_id: office_place_variant.id,     name: "Bureau", :work_number => "B08", :identification_number => "BUREAU"},
                     {variant_id: settlement_place_variant.id, name: "Silo bas", :work_number => "B01", :identification_number => "SILO_BAS"},
                     {variant_id: settlement_place_variant.id, name: "Fosse eaux brunes", :work_number => "B02", :identification_number => "FOSSE"},
                     {variant_id: animal_place_variant.id,     name: "Poulailler 2 (côté Forêt)", :work_number => "B10", :identification_number => "BAT_POULAILLER_2"}
                    ]
      unless Building.find_by_work_number(building[:work_number])
        Building.create!({:initial_owner => Entity.of_company, :born_at => born_at, :reservoir => false, :default_storage => Building.first}.merge(building))
        w.check_point
      end
    end

  end
    
  Ekylibre::fixturize :buildings_shapes do |w|
    #############################################################################
    buidling_file = Rails.root.join("test", "fixtures", "files", "buildings_2013.shp")
    if File.exists?(buidling_file.to_s)
      born_at = Time.new(1995, 1, 1, 10, 0, 0, "+00:00")
      RGeo::Shapefile::Reader.open(buidling_file.to_s, :srid => 2154) do |file|
        # puts "File contains #{file.num_records} records."
        file.each do |record|
          building = Building.find_by_work_number(record.attributes['WORK_NUMBE'])
          building ||= Building.create!(variant_id: standard_place_variant.id,
                                        name: record.attributes['DESCRIPTION'].to_s,
                                        :work_number => record.attributes['WORK_NUMBE'].to_s,
                                        :born_at => born_at,
                                        :default_storage => Building.first,
                                        :identification_number => record.attributes['NUMERO'].to_s)
          # raise record.geometry.inspect + record.geometry.methods.sort.to_sentence
          building.is_measured!(:shape, record.geometry, at: born_at)
          ind_area = building.shape_area
          building.is_measured!(:net_surface_area, ind_area.in_square_meter, at: born_at)
          # puts "Record number #{record.index}:"
          # puts "  Geometry: #{record.geometry.as_text}"
          # puts "  Attributes: #{record.attributes.inspect}"
          w.check_point
        end
      end
    end
  end

  Ekylibre::fixturize :building_divisions do |w|

    buidling_file = Rails.root.join("test", "fixtures", "files", "buildings_division_2013.shp")
    if File.exists?(buidling_file.to_s)

    RGeo::Shapefile::Reader.open(buidling_file.to_s, :srid => 2154) do |file|
      # puts "File contains #{file.num_records} records."
      born_at = Time.new(1995, 1, 1, 10, 0, 0, "+00:00")
      file.each do |record|
        # find the building_division if exist
        building_division   = BuildingDivision.find_by_work_number(record.attributes['WORK_NUMBE'])
        # import the correct product_nature_variant with the NOMEN attributes in shp file
        building_division_variant   = ProductNatureVariant.import_from_nomenclature(record.attributes['NOMEN'].to_sym)
        building_division_variant ||= ProductNatureVariant.import_from_nomenclature(:building_division)
        #  create the building_division
        building_division ||= BuildingDivision.create!(variant_id: building_division_variant.id,
                                                       name: record.attributes['DECRIPTION'].to_s,
                                                       :work_number => record.attributes['WORK_NUMBE'].to_s,
                                                       :born_at => born_at,
                                                       :identification_number => record.attributes['NUMERO'].to_s)
        building_division.is_measured!(:shape, record.geometry, at: born_at)
        ind_area = building_division.shape_area
        building_division.is_measured!(:net_surface_area, ind_area.in_square_meter, at: born_at)

        if record.attributes['CONTAINER'].to_s
          if building = Building.find_by_work_number(record.attributes['CONTAINER'].to_s)
            building.add(building_division, born_at)
            building_division.update_attributes(initial_container: building)
            building_division.save!
          end
        end
        
        # puts "Record number #{record.index}:"
        # puts "  Geometry: #{record.geometry.as_text}"
        # puts "  Attributes: #{record.attributes.inspect}"
        w.check_point
      end
    end
    end
  end

end
