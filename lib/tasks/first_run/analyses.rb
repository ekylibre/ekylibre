load_data :analyses do |loader|

  file = loader.path("lilco", "HistoIP_V.csv")
  if file.exist?
    loader.count :milk_analyses_import do |w|

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
                           :at => Date.civil(row[0].to_i, row[1].to_i, row[2].to_i),
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

  # @TODO need a method for each file in a folder like loader.glob('lca/*.csv') do |file|
  
  file = loader.path("galactea3", "cl_2014.csv")
  if file.exist?
    loader.count :milk_unitary_control_analyses_import do |w|

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

      trans_inhib = {
        "NEG" => "negative",
        "POS" => "positive"
      }

      CSV.foreach(file, :encoding => "UTF-8", :col_sep => "\t", :headers => true) do |row|
        r = OpenStruct.new(:at => (row[0].blank? ? nil : Date.civil(*row[0].to_s.split(/\//).reverse.map(&:to_i))),
                           :reference_number => row[1].to_s + row[5].to_s + row[6].to_s,
                           :animal_work_number => row[4],
                           :lactation_number => row[5],
                           :control_number => row[6],
                           :milk_daily_production => row[7],
                           :tb_daily_production => (row[9].blank? ? 0 : (row[9].to_d)/100).in_gram_per_liter,
                           :tp_daily_production => (row[10].blank? ? 0 : (row[10].to_d)/100).in_gram_per_liter,
                           :animal_state => row[11],
                           :somatic_cell_concentration => (row[12].blank? ? 0 : row[12].to_i).in_thousand_per_milliliter,
                           :calving_date => row[13],
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

          
          analysis.read!(:fat_matters_concentration, r.tb_daily_production)
          analysis.read!(:protein_matters_concentration, r.tp_daily_production)
          analysis.read!(:somatic_cell_concentration, r.somatic_cell_concentration)

        end
        w.check_point
      end
    end
  end
  
  

end
