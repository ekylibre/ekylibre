# -*- coding: utf-8 -*-
demo :productions do

  Ekylibre::fixturize :milk_production_analysis_import do |w|

    #############################################################################
    # import Milk result to make automatic quality indicators
    # @TODO
    #
    # add a product_nature
    product_nature_variant = ProductNature.import_from_nomenclature(:milk).default_variant

    # create a generic product to link analysis_indicator
    product   = OrganicMatter.find_by_name("lait_vache")
    product ||= OrganicMatter.create!(:name => "lait_vache", :identification_number => "MILK_FR_2010-2013", :work_number => "lait_2013", :born_at => Time.now, :variant_id => product_nature_variant.id, :owner_id => Entity.of_company.id) #

    trans_inhib = {
      "NEG" => "negative",
      "POS" => "positive"
    }

    file = Rails.root.join("test", "fixtures", "files", "HistoIP_V_1997_2013.csv")
    CSV.foreach(file, :encoding => "CP1252", :col_sep => "\t", :headers => true) do |row|
      analysis_on = Date.civil(row[0].to_i, row[1].to_i, 1)
      r = OpenStruct.new(:analysis_year => row[0],
                         :analysis_month => row[1],
                         :analysis_order => row[2],
                         :analysis_quality_indicator_germes => (row[3].blank? ? 0 : row[3].to_i),
                         :analysis_quality_indicator_inhib => (row[4].blank? ? "negative" : trans_inhib[row[4]]),
                         :analysis_quality_indicator_mg => (row[5].blank? ? 0 : (row[5].to_d)/100),
                         :analysis_quality_indicator_mp => (row[6].blank? ? 0 : (row[6].to_d)/100),
                         :analysis_quality_indicator_cellules => (row[7].blank? ? 0 : row[7].to_i),
                         :analysis_quality_indicator_buty => (row[8].blank? ? 0 : row[8].to_i),
                         :analysis_quality_indicator_cryo => (row[9].blank? ? 0.00 : row[9].to_d),
                         :analysis_quality_indicator_lipo => (row[10].blank? ? 0.00 : row[10].to_d),
                         :analysis_quality_indicator_igg => (row[11].blank? ? 0.00 : row[11].to_d),
                         :analysis_quality_indicator_uree => (row[12].blank? ? 0 : row[12].to_i),
                         :analysis_quality_indicator_salmon => row[13],
                         :analysis_quality_indicator_listeria => row[14],
                         :analysis_quality_indicator_staph => row[15],
                         :analysis_quality_indicator_coli => row[16],
                         :analysis_quality_indicator_pseudo => row[17],
                         :analysis_quality_indicator_ecoli => row[18]
                         )

      product.is_measured!(:total_bacteria_concentration, r.analysis_quality_indicator_germes.in_thousand_per_milliliter, :at => analysis_on)
      product.is_measured!(:inhibitors_presence, r.analysis_quality_indicator_inhib, :at => analysis_on)
      product.is_measured!(:fat_matters_concentration, r.analysis_quality_indicator_mg.in_gram_per_liter, :at => analysis_on)
      product.is_measured!(:protein_matters_concentration, r.analysis_quality_indicator_mp.in_gram_per_liter, :at => analysis_on)
      product.is_measured!(:cells_concentration, r.analysis_quality_indicator_cellules.in_thousand_per_milliliter, :at => analysis_on)
      product.is_measured!(:clostridial_spores_concentration, r.analysis_quality_indicator_buty.in_unity_per_liter, :at => analysis_on)
      product.is_measured!(:freezing_point_temperature, r.analysis_quality_indicator_cryo.in_celsius, :at => analysis_on)
      product.is_measured!(:lipolysis, r.analysis_quality_indicator_lipo.in_thousand_per_hectogram, :at => analysis_on)
      product.is_measured!(:immunoglobulins_concentration, r.analysis_quality_indicator_igg.in_unity_per_liter, :at => analysis_on)
      product.is_measured!(:urea_concentration, r.analysis_quality_indicator_uree.in_milligram_per_liter, :at => analysis_on)

      w.check_point
    end

  end

  Ekylibre::fixturize :activities_import do |w|
    #############################################################################



    # attributes to map family
    families = {
      "CEREA" => :straw_cereal_crops,
      "COPLI" => :oilseed_crops,
      "CUFOU" => :prairie,
      "ANIMX" => :cattle_farming
      #"XXXXX" => :none,
      #"NINCO" => :none
    }
    # attributes to map family by activity name
    families_by_activity_name = {
      "ORGE HIVER" => :straw_cereal_crops,
      "BLE TENDRE" => :straw_cereal_crops,
      "BLE DUR" => :straw_cereal_crops,
      "MAIS SEC" => :maize_crops,
      "TRITICALE" => :straw_cereal_crops,
      "JACHERES ANNUELLE" => :fallow_land,
      "TOURNESOL" => :oilseed_crops,
      "SORGHO" => :prairie,
      "PRAIRIE TEMPO+ARTIF" => :prairie,
      "BOVINS LAIT" => :cattle_farming,
      "VEAU 8-15 J" => :cattle_farming,
      "TAURILLONS LAIT" => :cattle_farming,
      "ADMINISTRATIF" => :exploitation,
      "BATIMENT" => :exploitation,
      "COMMERCIALISATION" => :sales,
      "MECANISATION" => :exploitation,
      "PERSONNEL" => :exploitation
    }
    # attributes to map nature
    natures = {
      "PRINC" => :main,
      "AUX" => :auxiliary,
      "" => :none
    }
    # Load file
    file = Rails.root.join("test", "fixtures", "files", "activities_ref_demo_3.csv")
    CSV.foreach(file, :encoding => "UTF-8", :col_sep => ",", :headers => true, :quote_char => "'") do |row|
      r = OpenStruct.new(:description => row[0],
                         :name => row[1].downcase.capitalize,
                         :family => families_by_activity_name[row[1]],
                         :product_nature_nomen => row[3].blank? ? nil :row[3].to_sym,
                         :nature => (natures[row[4]] || :none).to_s,
                         :campaign_name => row[5].blank? ? nil : row[5].to_s,
                         :work_number_land_parcel_storage => row[6].blank? ? nil : row[6].to_s
                         )
      land_parcel_support = CultivableLandParcel.find_by_work_number(r.work_number_land_parcel_storage)
      # Create a campaign if not exist
      if r.campaign_name.present?
        campaign = Campaign.find_by_name(r.campaign_name)
        campaign ||= Campaign.create!(:name => r.campaign_name, :closed => false)
      end
      # Create an activity if not exist
      activity   = Activity.find_by_description(r.description)
      activity ||= Activity.create!(:nature => r.nature, :family => r.family, :name => r.name, :description => r.description)
      if r.product_nature_nomen
        product_nature_sup = ProductNature.find_by_nomen(r.product_nature_nomen)
        if product_nature_sup.present?
          product_nature_variant_sup = ProductNatureVariant.find_by_nature_id(product_nature_sup.id)
        else
          product_nature_sup = ProductNature.import_from_nomenclature(r.product_nature_nomen)
          product_nature_variant_sup = product_nature_sup.default_variant
        end
        if product_nature_variant_sup and land_parcel_support.present?
          # find a production corresponding to campaign , activity and product_nature
          pro = Production.where(:campaign_id => campaign.id, :activity_id => activity.id, :product_nature_id => product_nature_sup.id).first
          # or create it
          pro ||= activity.productions.create!(:product_nature_id => product_nature_sup.id, :campaign_id => campaign.id, :static_support => true)
          # create a support for this production
          pro.supports.create!(:storage_id => land_parcel_support.id)
          # create a name for the plant correponding to product_nature_nomen in XML Nomenclature
          plant_name = (Nomen::ProductNatures.find(r.product_nature_nomen).human_name + " " + campaign.name + " " + land_parcel_support.work_number)
          # create a work number for the plant
          plant_work_nb = (r.product_nature_nomen.to_s + "-" + campaign.name + "-" + land_parcel_support.work_number)
          # create the plant
          plant = Plant.create!(:variant_id => product_nature_variant_sup.id, :work_number => plant_work_nb , :name => plant_name, :variety => product_nature_sup.variety, :born_at => Time.now, :owner_id => Entity.of_company.id)
          # localize the plant in the cultivable_land_parcel
          ProductLocalization.create!(:container_id => land_parcel_support.id, :product_id => plant.id, :nature => :interior, :started_at => Time.now, :arrival_cause => :birth)
        elsif product_nature_variant_sup
          pro = Production.where(:product_nature_id => product_nature_sup.id, :campaign_id => campaign.id, :activity_id => activity.id).first
          pro ||= activity.productions.create!(:product_nature_id => product_nature_sup.id, :campaign_id => campaign.id)
        end
      end
      w.check_point
    end
  end

  Ekylibre::fixturize :fertilizing_procedure_demo_data_1 do |w|
    #############################################################################
    ## Demo data for fertilizing
    ##############################################################################

    campaign = Campaign.find_by_name("2013")
    campaign ||= Campaign.create!(:name => "2013", :closed => false)
    sole_ble_nature = ProductNature.find_by_nomen("wheat_crop")
    sole_ble_nature ||= ProductNature.import_from_nomenclature(:wheat_crop)
    worker_variant = ProductNature.import_from_nomenclature(:manager).default_variant
    worker = worker_variant.products.create!(:name => "Brice")
    # create some indicator nature for fertilization
    # find some product for fertilization
    fertilizer_product = ProductNature.where(:nomen => "chemical_fertilizer").first.products.first
    fertilizer_product_prev = ProductNature.where(:nomen => "chemical_fertilizer").first.products.last
    # set indicator on product for fertilization

    #fertilizer_product.indicator_data.create!({:measure_unit => "kilograms_per_hectogram", :measured_at => Time.now }.merge(attributes))
    #fertilizer_product_prev.indicator_data.create!({:measure_unit => "kilograms_per_hectogram", :measured_at => Time.now }.merge(attributes))

    fertilizer_product.is_measured!(:nitrogen_concentration, 27.00.in_kilogram_per_hectogram, :at => Time.now)
    fertilizer_product.is_measured!(:potassium_concentration, 33.00.in_kilogram_per_hectogram, :at => Time.now)
    fertilizer_product.is_measured!(:phosphorus_concentration, 33.00.in_kilogram_per_hectogram, :at => Time.now)
    fertilizer_product_prev.is_measured!(:nitrogen_concentration, 27.00.in_kilogram_per_hectogram, :at => Time.now)
    fertilizer_product_prev.is_measured!(:potassium_concentration, 33.00.in_kilogram_per_hectogram, :at => Time.now)
    fertilizer_product_prev.is_measured!(:phosphorus_concentration, 33.00.in_kilogram_per_hectogram, :at => Time.now)


    production = Production.find_by_product_nature_id_and_campaign_id(sole_ble_nature.id, campaign.id)
    if production.nil?
      land_parcel_group_fert = CultivableLandParcel.find_by_work_number("PC22")
      if land_parcel_group_fert.nil?
        land_parcel_group_nature_variant = ProductNature.import_from_nomenclature(:cultivable_land_parcel).default_variant
        land_parcel_group_fert = CultivableLandParcel.create!(:variant_id => land_parcel_group_nature_variant.id,
                                                              :name => "Les Grands Pièces 1",
                                                              :work_number => "PC22",
                                                              :variety => "cultivable_land_parcel",
                                                              :born_at => Time.now,
                                                              :owner_id => Entity.of_company.id,
                                                              :identification_number => "PC22")
        land_parcel_group_shape = "01060000206A08000001000000010300000001000000100000003108AC1CBD0219418FC2F5C05BEC5841C976BE1F900319419CC4206854EC58419EEFA74657041941000000D050EC5841759318046F051941819543AB50EC5841713D0A57E60419416666663E4BEC584121B0726851051941819543F343EC5841E9263108AE051941CDCCCC6448EC584175931884D5051941E92631A045EC58410C022B0705061941B4C8765641EC5841C520B07200031941B81E85031AEC58413108AC1CC9021941295C8FCA1DEC58416DE7FBA903021941CDCCCCAC12EC584121B072E8C70119410681957314EC584148E17A94800119412DB29D7718EC584121B072683C0019413108AC5C34EC58413108AC1CBD0219418FC2F5C05BEC5841"
        land_parcel_group_fert.is_measured!(:shape, land_parcel_group_shape, :at => Time.now)
        ind_area = land_parcel_group_fert.shape_area
        land_parcel_group_fert.is_measured!(:net_surface_area, ind_area.in_square_meter, :at => Time.now)
      end
      production = Production.create!(:activity_id => Activity.find_by_family("straw_cereal_crops").id, :product_nature_id => sole_ble_nature.id, :campaign_id => campaign.id)
      production.supports.create!(:storage_id => land_parcel_group_fert.id)
    end



    # provisional fertilization procedure
    intervention_prev = Intervention.create!(:natures => "soil_enrichment", :procedure =>"mineral_fertilizing", :production_id => production.id, :provisional => true )
    
    
     # Create some procedure variable for fertilization
    for attributes in [{:actor_id => land_parcel_group_fert.id, :variable => "target"},
                       {:actor_id => fertilizer_product_prev.id, :variable => "input"},
                       {:actor_id => fertilizer_product_prev.id, :variable => "input"},
                       {:actor_id => worker.id, :variable => "worker"}
                      ]
    
      intervention_prev.casts.create!(attributes)
    end
    
    land_parcel_group_fert = production.supports.first.storage


    # Create some operation variable for fertilization
    for attributes in [{:started_at => (Time.now - 15.days), :stopped_at => (Time.now - 10.days)}]
      intervention_prev.operations.create!({:procedure_id => procedure_prev.id}.merge(attributes) )
    end

    # real fertilization procedure
    intervention_real = Intervention.create!(:natures => "soil_enrichment", :procedure =>"mineral_fertilizing", :production_id => production.id, :provisional_intervention_id => procedure_prev.id, :state => "done")


    # Create some procedure variable for fertilization
    for attributes in [{:target_id => land_parcel_group_fert.id, :role => "target",
                         :indicator => "net_surface_area",
                         :measure_quantity => 5.0, :measure_unit => "hectare"},
                       {:target_id => fertilizer_product.id, :role => "input",
                         :indicator => "net_weight",
                         :measure_quantity => 575.00, :measure_unit => "kilogram"},
                       {:target_id => fertilizer_product.id, :role => "input",
                         :indicator => "net_weight",
                         :measure_quantity => 375.00, :measure_unit => "kilogram"}
                      ]
      ProcedureVariable.create!({:procedure_id => procedure_real.id}.merge(attributes) )
    end

    # Create some operation variable for fertilization
    for attributes in [{:started_at => (Time.now - 2.days), :stopped_at => Time.now}]
      procedure_real.operations.create!({:procedure_id => procedure_real.id}.merge(attributes) )
    end
    w.check_point
  end

  Ekylibre::fixturize :fertilizing_procedure_demo_data_2 do |w|
    #############################################################################
    ## Demo data for fertilizing
    ##############################################################################

    campaign = Campaign.find_by_name("2012")
    campaign ||= Campaign.create!(:name => "2012", :closed => false)
    sole_ble_nature = ProductNature.find_by_nomen("wheat_crop")
    sole_ble_nature ||= ProductNature.import_from_nomenclature(:wheat_crop)
    # create some indicator nature for fertilization
    # find some product for fertilization
    fertilizer_product = ProductNature.where(:nomen => "chemical_fertilizer").first.products.first
    fertilizer_product_prev = ProductNature.where(:nomen => "chemical_fertilizer").first.products.last
    # set indicator on product for fertilization

    #fertilizer_product.indicator_data.create!({:measure_unit => "kilograms_per_hectogram", :measured_at => Time.now }.merge(attributes))
    #fertilizer_product_prev.indicator_data.create!({:measure_unit => "kilograms_per_hectogram", :measured_at => Time.now }.merge(attributes))

    production = Production.find_by_product_nature_id_and_campaign_id(sole_ble_nature.id, campaign.id)

    if production.nil?
      production = Production.create!(:activity_id => Activity.find_by_family("straw_cereal_crops").id, :product_nature_id => sole_ble_nature.id, :campaign_id => campaign.id)
    end
    if production.supports.first.nil?
      land_parcel_group_fert = CultivableLandParcel.find_by_work_number("PC22")
      if land_parcel_group_fert.nil?
        land_parcel_group_nature_variant = ProductNature.import_from_nomenclature(:cultivable_land_parcel).default_variant
        land_parcel_group_fert = CultivableLandParcel.create!(:variant_id => land_parcel_group_nature_variant.id,
                                                              :name => "Les Grands Pièces 1",
                                                              :work_number => "PC22",
                                                              :variety => "cultivable_land_parcel",
                                                              :born_at => Time.now,
                                                              :owner_id => Entity.of_company.id,
                                                              :identification_number => "PC22")
        land_parcel_group_shape = "01060000206A08000001000000010300000001000000100000003108AC1CBD0219418FC2F5C05BEC5841C976BE1F900319419CC4206854EC58419EEFA74657041941000000D050EC5841759318046F051941819543AB50EC5841713D0A57E60419416666663E4BEC584121B0726851051941819543F343EC5841E9263108AE051941CDCCCC6448EC584175931884D5051941E92631A045EC58410C022B0705061941B4C8765641EC5841C520B07200031941B81E85031AEC58413108AC1CC9021941295C8FCA1DEC58416DE7FBA903021941CDCCCCAC12EC584121B072E8C70119410681957314EC584148E17A94800119412DB29D7718EC584121B072683C0019413108AC5C34EC58413108AC1CBD0219418FC2F5C05BEC5841"
        land_parcel_group_fert.is_measured!(:shape, land_parcel_group_shape, :at => Time.now)
        ind_area = land_parcel_group_fert.shape_area
        land_parcel_group_fert.is_measured!(:net_surface_area, ind_area.in_square_meter, :at => Time.now)
      end
      production.supports.create!(:storage_id => land_parcel_group_fert.id)
    end


    # provisional fertilization procedure
    procedure_prev = Procedure.create!(:natures => "soil_enrichment", :nomen =>"mineral_fertilizing", :production_id => production.id, :provisional => true )

    land_parcel_group_fert = production.supports.first.storage

    # Create some procedure variable for fertilization
    for attributes in [{:target_id => land_parcel_group_fert.id, :role => "target",
                         :indicator => "net_surface_area",
                         :measure_quantity => "5.00", :measure_unit => "hectare"},
                       {:target_id => fertilizer_product_prev.id, :role => "input",
                         :indicator => "net_weight",
                         :measure_quantity => "475.00", :measure_unit => "kilogram"},
                       {:target_id => fertilizer_product_prev.id, :role => "input",
                         :indicator => "net_weight",
                         :measure_quantity => "275.00", :measure_unit => "kilogram"}
                      ]
      ProcedureVariable.create!({:procedure_id => procedure_prev.id}.merge(attributes) )
    end

    # Create some operation variable for fertilization
    for attributes in [{:started_at => (Time.now - 380.days), :stopped_at => (Time.now - 370.days)}]
      procedure_prev.operations.create!({:procedure_id => procedure_prev.id}.merge(attributes) )
    end

    # real fertilization procedure
    procedure_real = Procedure.create!(:natures => "soil_enrichment", :nomen =>"mineral_fertilizing", :production_id => production.id, :provisional_procedure_id => procedure_prev.id, :state => "done")


    # Create some procedure variable for fertilization
    for attributes in [{:target_id => land_parcel_group_fert.id, :role => "target",
                         :indicator => "net_surface_area",
                         :measure_quantity => 5.0, :measure_unit => "hectare"},
                       {:target_id => fertilizer_product.id, :role => "input",
                         :indicator => "net_weight",
                         :measure_quantity => 575.00, :measure_unit => "kilogram"},
                       {:target_id => fertilizer_product.id, :role => "input",
                         :indicator => "net_weight",
                         :measure_quantity => 375.00, :measure_unit => "kilogram"}
                      ]
      ProcedureVariable.create!({:procedure_id => procedure_real.id}.merge(attributes) )
    end

    # Create some operation variable for fertilization
    for attributes in [{:started_at => (Time.now - 400.days), :stopped_at => (Time.now - 420.days)}]
      procedure_real.operations.create!({:procedure_id => procedure_real.id}.merge(attributes) )
    end
    w.check_point
  end

  Ekylibre::fixturize :animal_treatment_procedure_demo_data_1 do |w|
    ##############################################################################
    ## Demo data for animal treatment
    ##############################################################################

    worker_variant = ProductNature.import_from_nomenclature(:manager).default_variant
    worker = Worker.create!(:variant_id => worker_variant.id, :name => "Christian")

    worker_variant = ProductNature.import_from_nomenclature(:technician).default_variant
    worker = Worker.create!(:variant_id => worker_variant.id, :name => "Yvan")

    # add some credentials in preferences
    cattling_number = Preference.create!(:nature => :string, :name => "services.synel17.login", :value => "17387001")

    #sanitary_product_nature_variant = ProductNatureVariant.find_by_nature_name("Animal medicine")
    sanitary_product_nature_variant = ProductNature.import_from_nomenclature(:animal_medicine).default_variant
    campaign = Campaign.find_by_name("2013")
    animal_group_nature = ProductNature.find_by_nomen("female_adult_cow")
    animal_group_nature ||= ProductNature.import_from_nomenclature("female_adult_cow")
    animal_activity = Activity.find_by_description("8200")
    animal_activity ||= Activity.create!(:nature => "main", :family => "cattle_farming", :name => "VL", :description => "8200")
    animal_production = Production.find_by_product_nature_id_and_campaign_id(animal_group_nature.id, campaign.id)
    animal_production ||= Production.create!(:product_nature_id => animal_group_nature.id, :campaign_id => campaign.id, :activity_id => animal_activity.id)
    # create an animal medicine product
    animal_medicine_product = AnimalMedicine.find_by_name("acetal") || AnimalMedicine.create!(:name => "acetal", :identification_number => "FR_589698256352", :work_number => "FR_589698256352", :born_at => Time.now, :variant_id => sanitary_product_nature_variant.id, :owner_id => Entity.of_company.id)

    animal_medicine_product.is_measured!(:meat_withdrawal_period, 5.in_day, :at => Time.now)
    animal_medicine_product.is_measured!(:milk_withdrawal_period, 5.in_day, :at => Time.now)


    animal_medicine_product_1   = AnimalMedicine.find_by_name("advocine") || AnimalMedicine.create!(:name => "advocine", :identification_number => "FR_589698256362", :work_number => "FR_589698256362", :born_at => Time.now, :variant_id => sanitary_product_nature_variant.id, :owner_id => Entity.of_company.id)

    animal_medicine_product_1.is_measured!(:meat_withdrawal_period, 8.in_day, :at => Time.now)
    animal_medicine_product_1.is_measured!(:milk_withdrawal_period, 4.in_day, :at => Time.now)

    # import a document "prescription paper"
    document = Document.create!(:key => "20130724_prescription_001", :name => "prescritpion_001", :nature => "prescription" )
    File.open(Rails.root.join("test", "fixtures", "files", "prescription_1.jpg"),"rb") do |f|
      document.archive(f.read, :jpg)
    end

    # create a prescription
    prescription = Prescription.create!(:reference_number => "210000303",
                                        :prescriptor_id => Entity.last.id,
                                        :document_id => document.id,
                                        :delivered_on => "2012-10-24",
                                        :description => "Lotagen, Cobactan, Rotavec"
                                        )

    # select an animal to declare on an incident
    animal = Animal.last

    # Add an incident
    incident = animal.incidents.create!(:name => "Mammitte",
                                        :nature => "mammite",
                                        :observed_at => "2013-10-22",
                                        :description => "filament blanc lors de la traite",
                                        :priority => "5",
                                        :gravity => "3"
                                        )


    # treatment procedure
    procedure = incident.procedures.create!(:natures => "animal_care",
                                            :nomen =>"animal_treatment",
                                            :state => "done",
                                            :production_id => animal_production.id,
                                            :prescription_id => prescription.id
                                            )

    # Create some procedure variable
    for attributes in [{:target_id => worker.id, :role => "worker",
                         :indicator => "usage_duration",
                         :measure_quantity => "0.50", :measure_unit => "hour"},
                       {:target_id => animal_medicine_product.id, :role => "input",
                         :indicator => "net_volume",
                         :measure_quantity => "50.00", :measure_unit => "milliliter"},
                       {:target_id => animal_medicine_product_1.id, :role => "input",
                         :indicator => "net_volume",
                         :measure_quantity => "8.00", :measure_unit => "milliliter"},
                       {:target_id => animal.id, :role => "target",
                         :indicator => "population",
                         :measure_quantity => "1.00", :measure_unit => "unity"}
                      ]
      ProcedureVariable.create!({:procedure_id => procedure.id}.merge(attributes) )
    end

    # Create some operation variable
    for attributes in [{:started_at => (Time.now - 2.days), :stopped_at => Time.now}]
      procedure.operations.create!({:procedure_id => procedure.id}.merge(attributes) )
    end
    w.check_point
  end

  Ekylibre::fixturize :animal_treatment_procedure_demo_data_2 do |w|
    ##############################################################################
    ## Demo data for animal treatment
    ##############################################################################

    worker_variant = ProductNature.import_from_nomenclature(:technician).default_variant
    worker = Worker.create!(:variant_id => worker_variant.id, :name => "David")

    # add some credentials in preferences
    cattling_number = Preference.find_by_name("services.synel17.login")

    #sanitary_product_nature_variant = ProductNatureVariant.find_by_nature_name("Animal medicine")
    sanitary_product_nature_variant = ProductNatureVariant.find_by_nature_name("animal_medicine")
    campaign = Campaign.find_by_name("2012")
    animal_group_nature = ProductNature.find_by_nomen("female_adult_cow")
    animal_group_nature ||= ProductNature.import_from_nomenclature("female_adult_cow")
    animal_activity = Activity.find_by_description("8200")
    animal_activity ||= Activity.create!(:nature => "main", :family => "cattle_farming", :name => "VL", :description => "8200")
    animal_production = Production.find_by_product_nature_id_and_campaign_id(animal_group_nature.id, campaign.id)
    animal_production ||= Production.create!(:product_nature_id => animal_group_nature.id, :campaign_id => campaign.id, :activity_id => animal_activity.id)
    # create an animal medicine product
    animal_medicine_product   = AnimalMedicine.find_by_name("acetal")
    animal_medicine_product ||= AnimalMedicine.create!(:name => "acetal", :identification_number => "FR_589698256352", :work_number => "FR_589698256352", :born_at => Time.now, :variant_id => sanitary_product_nature_variant.id, :owner_id => Entity.of_company.id)

    animal_medicine_product.is_measured!(:meat_withdrawal_period, 5.in_day, :at => Time.now)
    animal_medicine_product.is_measured!(:milk_withdrawal_period, 5.in_day, :at => Time.now)


    # select an animal to declare on an incident
    animal = Animal.last

    # Add an incident
    incident = animal.incidents.create!(:name => "Grippe",
                                        :nature => "other",
                                        :observed_at => "2012-10-22",
                                        :description => "reste couchée et est très chaude",
                                        :priority => "3",
                                        :gravity => "5"
                                        )


    # treatment procedure
    procedure = incident.procedures.create!(:natures => "animal_care",
                                            :nomen =>"animal_treatment",
                                            :state => "done",
                                            :production_id => animal_production.id
                                            )

    # Create some procedure variable
    for attributes in [{:target_id => worker.id, :role => "worker",
                         :indicator => "usage_duration",
                         :measure_quantity => "0.50", :measure_unit => "hour"},
                       {:target_id => animal_medicine_product.id, :role => "input",
                         :indicator => "net_volume",
                         :measure_quantity => "50.00", :measure_unit => "milliliter"},
                       {:target_id => animal_medicine_product.id, :role => "input",
                         :indicator => "net_volume",
                         :measure_quantity => "10.00", :measure_unit => "milliliter"},
                       {:target_id => animal.id, :role => "target",
                         :indicator => "population",
                         :measure_quantity => "1.00", :measure_unit => "unity"}
                      ]
      ProcedureVariable.create!({:procedure_id => procedure.id}.merge(attributes) )
    end

    # Create some operation variable
    for attributes in [{:started_at => (Time.now - 361.days), :stopped_at => (Time.now - 360.days)}]
      procedure.operations.create!({:procedure_id => procedure.id}.merge(attributes) )
    end
    w.check_point
  end

end
