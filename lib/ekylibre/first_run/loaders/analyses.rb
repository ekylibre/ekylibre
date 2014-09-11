# -*- coding: utf-8 -*-
Ekylibre::FirstRun.add_loader :analyses do |first_run|

  # Collect activity family matchings
  landparcels_transcode = {}.with_indifferent_access

  file = first_run.path("charentes_alliance", "landparcels_transcode.csv")
  if file.exist?
    CSV.foreach(file, headers: true) do |row|
      landparcels_transcode[row[0]] = row[1].to_s
    end
  end

  soil_natures_transcode = {}.with_indifferent_access

  file = first_run.path("charentes_alliance", "soil_natures_transcode.csv")
  if file.exist?
    CSV.foreach(file, headers: true) do |row|
      soil_natures_transcode[row[0]] = row[1].to_sym
    end
  end


  file = first_run.path("charentes_alliance", "analyses_sol.txt")
  if file.exist?
    first_run.count :soil_analyses_import do |w|

      unless analyser = LegalEntity.where("LOWER(full_name) LIKE ?", "%AGRO-Systèmes%".mb_chars.downcase).first
        analyser = LegalEntity.create!(last_name: "AGRO-Systèmes",
                                       nature: :legal_entity,
                                       vat_number: "FR00123456789",
                                       supplier: true, client: false,
                                       mails_attributes: {
                                         0 => {
                                           canal: "mail",
                                           mail_line_4: "Route de Saint Roch",
                                           mail_line_6: "37390 La Membrolle Choisille",
                                           mail_country: :fr
                                         }
                                       },
                                       emails_attributes: {
                                         0 => {
                                           canal: "email",
                                           coordinate: "contact@agro-systemes.fr"
                                         }
                                       })
      end

      CSV.foreach(file, :encoding => "CP1252", :col_sep => "\t", :headers => true) do |row|
        r = OpenStruct.new(:code_distri => (row[0].blank? ? nil : row[0].to_s),
                           :reference_number => row[6].to_s,
                           :at => (row[7].blank? ? nil : Date.civil(*row[7].to_s.split(/\//).reverse.map(&:to_i))),
                           :landparcel_work_number => row[8].blank? ? nil : landparcels_transcode[row[8]],
                           :analyse_soil_nature => row[10].blank? ? nil : soil_natures_transcode[row[10]],
                           :organic_matter_concentration => row[38].blank? ? nil : (row[38].to_d).in_percent,
                           :potential_hydrogen => row[41].blank? ? nil : row[41].to_d,
                           :cation_exchange_capacity => row[47].blank? ? nil : (row[47].to_d).in_milliequivalent_per_hundred_gram,
                           :p2o5_olsen_ppm_value => row[49].blank? ? nil : (row[49].to_d).in_parts_per_million,
                           :p_ppm_value => row[49].blank? ? nil : ((row[49].to_d)*0.436).in_parts_per_million,
                           :k2o_ppm_value => row[55].blank? ? nil : (row[55].to_d).in_parts_per_million,
                           :k_ppm_value => row[55].blank? ? nil : ((row[55].to_d)*0.83).in_parts_per_million,
                           :mg_ppm_value => row[61].blank? ? nil : (row[61].to_d).in_parts_per_million,
                           :b_ppm_value => row[82].blank? ? nil : (row[82].to_d).in_parts_per_million,
                           :zn_ppm_value => row[85].blank? ? nil : (row[85].to_d).in_parts_per_million,
                           :mn_ppm_value => row[88].blank? ? nil : (row[88].to_d).in_parts_per_million,
                           :cu_ppm_value => row[91].blank? ? nil : (row[91].to_d).in_parts_per_million,
                           :fe_ppm_value => row[94].blank? ? nil : (row[94].to_d).in_parts_per_million,
                           :sampled_at => (row[179].blank? ? nil : Date.civil(*row[179].to_s.split(/\//).reverse.map(&:to_i)))
                           )






        unless analysis = Analysis.where(reference_number: r.reference_number, analyser: analyser).first
          analysis = Analysis.create!(reference_number: r.reference_number, nature: "soil_analysis",
                                      analyser: analyser, sampled_at: r.sampled_at, analysed_at: r.at
                                      )

          analysis.read!(:soil_nature, r.analyse_soil_nature) if r.analyse_soil_nature
          analysis.read!(:organic_matter_concentration, r.organic_matter_concentration) if r.organic_matter_concentration
          analysis.read!(:potential_hydrogen, r.potential_hydrogen) if r.potential_hydrogen
          analysis.read!(:cation_exchange_capacity, r.cation_exchange_capacity) if r.cation_exchange_capacity
          analysis.read!(:phosphate_concentration, r.p2o5_olsen_ppm_value) if r.p2o5_olsen_ppm_value
          analysis.read!(:potash_concentration, r.k2o_ppm_value) if r.k2o_ppm_value
          analysis.read!(:magnesium_concentration, r.mg_ppm_value) if r.mg_ppm_value
          analysis.read!(:boron_concentration, r.b_ppm_value) if r.b_ppm_value
          analysis.read!(:zinc_concentration, r.zn_ppm_value) if r.zn_ppm_value
          analysis.read!(:manganese_concentration, r.mn_ppm_value) if r.mn_ppm_value
          analysis.read!(:copper_concentration, r.cu_ppm_value) if r.cu_ppm_value
          analysis.read!(:iron_concentration, r.fe_ppm_value) if r.fe_ppm_value

        end
        # if an lan_parcel exist , link to analysis
        if land_parcel = LandParcel.find_by_work_number(r.landparcel_work_number)
          analysis.product = land_parcel
          analysis.save!
          land_parcel.read!(:soil_nature, r.analyse_soil_nature, at: r.sampled_at) if r.analyse_soil_nature
          land_parcel.read!(:phosphorus_concentration, r.p_ppm_value, at: r.sampled_at) if r.p_ppm_value
          land_parcel.read!(:potassium_concentration, r.k_ppm_value, at: r.sampled_at) if r.k_ppm_value
        end

        w.check_point
      end
    end
  end

  file = first_run.path("charentes_alliance", "analyses_eau.txt")
  if file.exist?
    first_run.count :water_analyses_import do |w|

      unless analyser = LegalEntity.where("LOWER(full_name) LIKE ?", "%AGRO-Systèmes%".mb_chars.downcase).first
        analyser = LegalEntity.create!(last_name: "AGRO-Systèmes",
                                       nature: :legal_entity,
                                       vat_number: "FR00123456789",
                                       supplier: true, client: false,
                                       mails_attributes: {
                                         0 => {
                                           canal: "mail",
                                           mail_line_4: "Route de Saint Roch",
                                           mail_line_6: "37390 La Membrolle Choisille",
                                           mail_country: :fr
                                         }
                                       },
                                       emails_attributes: {
                                         0 => {
                                           canal: "email",
                                           coordinate: "contact@agro-systemes.fr"
                                         }
                                       })
      end

      CSV.foreach(file, :encoding => "CP1252", :col_sep => "\t", :headers => true) do |row|
        r = OpenStruct.new(:code_distri => (row[0].blank? ? nil : row[0].to_s),
                           :reference_number => row[6].to_s,
                           :at => (row[7].blank? ? nil : Date.civil(*row[7].to_s.split(/\//).reverse.map(&:to_i))),
                           :water_work_number => row[8].blank? ? nil : landparcels_transcode[row[8]],
                           :potential_hydrogen => row[9].blank? ? nil : row[9].to_d,
                           :nitrogen_concentration => row[10].blank? ? nil : (row[10].to_d).in_percent,
                           :sampled_at => (row[12].blank? ? nil : Date.civil(*row[12].to_s.split(/\//).reverse.map(&:to_i)))
                           )

        unless analysis = Analysis.where(reference_number: r.reference_number, analyser: analyser).first
          analysis = Analysis.create!(reference_number: r.reference_number, nature: "water_analysis",
                                      analyser: analyser, sampled_at: r.sampled_at, analysed_at: r.at
                                      )

          analysis.read!(:potential_hydrogen, r.potential_hydrogen) if r.potential_hydrogen
          analysis.read!(:nitrogen_concentration, r.nitrogen_concentration) if r.nitrogen_concentration

        end
        # if an lan_parcel exist, link to analysis
        if water = Matter.find_by_variety('water')
          analysis.product = water
          analysis.save!
          water.read!(:potential_hydrogen, r.potential_hydrogen, at: r.sampled_at) if r.potential_hydrogen
          water.read!(:nitrogen_concentration, r.nitrogen_concentration, at: r.sampled_at) if r.nitrogen_concentration
        end

        w.check_point
      end
    end
  end


  file = first_run.path("lilco", "HistoIP_V.csv")
  if file.exist?
    first_run.count :milk_analyses_import do |w|

      unless analyser = LegalEntity.where("LOWER(full_name) LIKE ?", "%Lilco%".mb_chars.downcase).first
        analyser = LegalEntity.create!(last_name: "Lilco",
                                       nature: :cooperative,
                                       vat_number: "FR00123456789",
                                       supplier: true, client: false,
                                       mails_attributes: {
                                         0 => {
                                           canal: "mail",
                                           mail_line_4: "44 Rue Jean Jaures",
                                           mail_line_6: "17700 SURGERES",
                                           mail_country: :fr
                                         }
                                       },
                                       emails_attributes: {
                                         0 => {
                                           canal: "email",
                                           coordinate: "contact@lilco-s.com"
                                         }
                                       })
      end

      # import Milk result to make automatic quality indicators
      #product_nature_variant = ProductNatureVariant.import_from_nomenclature(:cow_milk)

      #born_at = Time.new(1997, 1, 1, 10, 0, 0, "+00:00")

      # create a generic product to link analysis_indicator
      #product   = OrganicMatter.find_by_name("lait_vache")
      #product ||= OrganicMatter.create!( :variant_id => product_nature_variant.id, :name => "lait_vache", :identification_number => "MILK_FR_1997-2013", :work_number => "lait_2013", :initial_born_at => born_at, :initial_owner_id => Entity.of_company.id, :default_storage => Equipment.find_by_name("Tank"))

      trans_inhib = {
        "NEG" => "negative",
        "POS" => "positive"
      }

      CSV.foreach(file, :encoding => "CP1252", :col_sep => "\t", :headers => true) do |row|
        r = OpenStruct.new(:year => row[0],
                           :month => row[1],
                           :order => row[2],
                           :reference_number => (row[0].to_s + row[1].to_s + row[2].to_s),
                           :at => Date.civil(row[0].to_i, row[1].to_i, row[2].to_i*9),
                           :germes => (row[3].blank? ? 0 : row[3].to_i).in_thousand_per_milliliter,
                           :inhib => (row[4].blank? ? "negative" : trans_inhib[row[4]]),
                           :mg => (row[5].blank? ? 0 : (row[5].to_d)/100).in_gram_per_liter,
                           :mp => (row[6].blank? ? 0 : (row[6].to_d)/100).in_gram_per_liter,
                           :cells => (row[7].blank? ? 0 : row[7].to_i).in_thousand_per_milliliter,
                           :buty => (row[8].blank? ? 0 : row[8].to_i).in_unity_per_liter,
                           :cryo => (row[9].blank? ? 0.00 : row[9].to_d).in_celsius,
                           :lipo => (row[10].blank? ? 0.00 : row[10].to_d).in_thousand_per_hectogram,
                           :igg => (row[11].blank? ? 0.00 : row[11].to_d).in_unity_per_liter,
                           :uree => (row[12].blank? ? 0 : row[12].to_i).in_milligram_per_liter,
                           :salmon => row[13],
                           :listeria => row[14],
                           :staph => row[15],
                           :coli => row[16],
                           :pseudo => row[17],
                           :ecoli => row[18]
                           )

        unless analysis = Analysis.where(reference_number: r.reference_number, analyser: analyser).first
          analysis = Analysis.create!(reference_number: r.reference_number,
                                      nature: "cow_milk_analysis",
                                      analyser: analyser,
                                      analysed_at: r.at,
                                      sampled_at: r.at
                                      )

          analysis.read!(:total_bacteria_concentration, r.germes)
          analysis.read!(:inhibitors_presence, r.inhib)
          analysis.read!(:fat_matters_concentration, r.mg)
          analysis.read!(:protein_matters_concentration, r.mp)
          analysis.read!(:somatic_cell_concentration, r.cells)
          analysis.read!(:clostridial_spores_concentration, r.buty)
          analysis.read!(:freezing_point_temperature, r.cryo)
          analysis.read!(:lipolysis, r.lipo)
          analysis.read!(:immunoglobulins_concentration, r.igg)
          analysis.read!(:urea_concentration, r.uree)

        end
        w.check_point
      end
    end
  end

  # @TODO need a method for each file in a folder like first_run.glob('lca/*.csv') do |file|

  file = first_run.path("galactea3", "cl_all.csv")
  if file.exist?
    first_run.count :milk_unitary_control_analyses_import do |w|

      unless analyser = LegalEntity.where("LOWER(full_name) LIKE ?", "%Atlantic Conseil Elevage%".mb_chars.downcase).first
        analyser = LegalEntity.create!(last_name: "Atlantic Conseil Elevage",
                                       nature: :cooperative,
                                       vat_number: "FR00123456789",
                                       supplier: true, client: false,
                                       mails_attributes: {
                                         0 => {
                                           canal: "mail",
                                           mail_line_4: "CS 10015 - Les Rochettes",
                                           mail_line_6: "85036 La Roche-sur-Yon",
                                           mail_country: :fr
                                         }
                                       },
                                       emails_attributes: {
                                         0 => {
                                           canal: "email",
                                           coordinate: "accueil@atlantic-conseil-elevage.fr"
                                         }
                                       })
      end

      # import Milk result to make automatic quality indicators
      #product_nature_variant = ProductNatureVariant.import_from_nomenclature(:cow_milk)

      #born_at = Time.new(1997, 1, 1, 10, 0, 0, "+00:00")

      # create a generic product to link analysis_indicator
      #product   = OrganicMatter.find_by_name("lait_vache")
      #product ||= OrganicMatter.create!( :variant_id => product_nature_variant.id, :name => "lait_vache", :identification_number => "MILK_FR_1997-2013", :work_number => "lait_2013", :initial_born_at => born_at, :initial_owner_id => Entity.of_company.id, :default_storage => Equipment.find_by_name("Tank"))

      trans_animal_state = {
        "M" => :bad,
        "S" => :good,
        "D" => :bad
      }

      CSV.foreach(file, :encoding => "UTF-8", :col_sep => "\t", :headers => true) do |row|
        r = OpenStruct.new(:at => (row[0].blank? ? nil : Date.civil(*row[0].to_s.split(/\//).reverse.map(&:to_i))),
                           :reference_number => row[1].to_s + "-L" + row[5].to_s + "-C" + row[6].to_s,
                           :animal_work_number => row[4].to_s,
                           :lactation_number => row[5].to_s,
                           :control_number => row[6].to_s,
                           :milk_daily_production => row[7].blank? ? nil : (row[7].to_d).in_kilogram_per_day,
                           :tb_daily_production => row[9].blank? ? nil : (row[9].to_d).in_gram_per_liter,
                           :tp_daily_production => row[10].blank? ? nil : (row[10].to_d).in_gram_per_liter,
                           :animal_state => (row[11].blank? ? nil : trans_animal_state[row[11].to_s]),
                           :somatic_cell_concentration => row[12].blank? ? nil : (row[12].to_i).in_thousand_per_milliliter,
                           :calving_date => (row[13].blank? ? nil : Date.civil(*row[0].to_s.split(/\//).reverse.map(&:to_i))),
                           :day_from_calving_date => row[14],
                           :milk_production_from_calving_date => row[15],
                           :tb_average_production => row[16],
                           :tp_average_production => row[17],
                           :standard_milk_production_from_calving_date => row[18]
                           )

        unless analysis = Analysis.where(reference_number: r.reference_number, analyser: analyser).first
          analysis = Analysis.create!(reference_number: r.reference_number, nature: "unitary_cow_milk_analysis",
                                      analyser: analyser, sampled_at: r.at, analysed_at: r.at
                                      )

          analysis.read!(:fat_matters_concentration, r.tb_daily_production) if r.tb_daily_production != nil
          analysis.read!(:protein_matters_concentration, r.tp_daily_production) if r.tp_daily_production != nil
          analysis.read!(:somatic_cell_concentration, r.somatic_cell_concentration) if r.somatic_cell_concentration != nil
          analysis.read!(:healthy, r.animal_state) if r.animal_state != nil
          analysis.read!(:milk_daily_production, r.milk_daily_production) if r.milk_daily_production != nil

        end
        # if an animal exist , link to analysis
        if animal = Animal.find_by_work_number(r.animal_work_number)
          analysis.product = animal
          analysis.save!
          animal.read!(:healthy, true,  at: r.at, force: true) if r.animal_state == :good
          animal.read!(:healthy, false,  at: r.at, force: true) if r.animal_state == :bad
        end

        w.check_point
      end
    end
  end

  file = first_run.path("bovins_croissance", "perf.csv")
  if file.exist?
    first_run.count :weight_unitary_control_analyses_import do |w|

      CSV.foreach(file, :encoding => "CP1252", :col_sep => "\t", :headers => true) do |row|
        r = OpenStruct.new(:animal_weight_at_birth => (row[13].blank? ? nil : row[13].to_d).in_kilogram,
                           :animal_work_number => row[18].to_s,
                           :first_weighting_at => (row[52].blank? ? nil : Date.civil(*row[52].to_s.split(/\//).reverse.map(&:to_i))),
                           :first_weighting_value => row[53].blank? ? nil : (row[53].to_d).in_kilogram,
                           :second_weighting_at => (row[55].blank? ? nil : Date.civil(*row[55].to_s.split(/\//).reverse.map(&:to_i))),
                           :second_weighting_value => row[56].blank? ? nil : (row[56].to_d).in_kilogram,
                           :third_weighting_at => (row[58].blank? ? nil : Date.civil(*row[58].to_s.split(/\//).reverse.map(&:to_i))),
                           :third_weighting_value => row[59].blank? ? nil : (row[59].to_d).in_kilogram,
                           :fourth_weighting_at => (row[61].blank? ? nil : Date.civil(*row[61].to_s.split(/\//).reverse.map(&:to_i))),
                           :fourth_weighting_value => row[62].blank? ? nil : (row[62].to_d).in_kilogram
                           )
        # if an animal exist , link to weight
        if animal = Animal.find_by_work_number(r.animal_work_number)
          animal.read!(:net_mass, r.animal_weight_at_birth,  at: animal.born_at, force: true) if r.animal_weight_at_birth
          animal.read!(:net_mass, r.first_weighting_value,  at: r.first_weighting_at, force: true) if r.first_weighting_at
          animal.read!(:net_mass, r.second_weighting_value,  at: r.second_weighting_at, force: true) if r.second_weighting_at
          animal.read!(:net_mass, r.third_weighting_value,  at: r.third_weighting_at, force: true) if r.third_weighting_at
          animal.read!(:net_mass, r.fourth_weighting_value,  at: r.fourth_weighting_at, force: true) if r.fourth_weighting_at
        end

        w.check_point
      end
    end
  end


end
