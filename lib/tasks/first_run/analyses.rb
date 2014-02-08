load_data :analyses do |loader|

  file = loader.path("milk_analyses.csv")
  if file.exist?
    loader.count :milk_analyses_import do |w|

      # import Milk result to make automatic quality indicators
      product_nature_variant = ProductNatureVariant.import_from_nomenclature(:cow_milk)
      born_at = Time.new(1997, 1, 1, 10, 0, 0, "+00:00")

      # create a generic product to link analysis_indicator
      product   = OrganicMatter.find_by_name("lait_vache")
      product ||= OrganicMatter.create!( :variant_id => product_nature_variant.id, :name => "lait_vache", :identification_number => "MILK_FR_1997-2013", :work_number => "lait_2013", :initial_born_at => born_at, :initial_owner_id => Entity.of_company.id, :default_storage => Equipment.find_by_name("Tank"))

      trans_inhib = {
        "NEG" => "negative",
        "POS" => "positive"
      }

      CSV.foreach(file, :encoding => "CP1252", :col_sep => "\t", :headers => true) do |row|
        r = OpenStruct.new(:year => row[0],
                           :month => row[1],
                           :order => row[2],
                           :at => Date.civil(row[0].to_i, row[1].to_i, 1),
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

        product.read!(:total_bacteria_concentration, r.germes, at: r.at)
        product.read!(:inhibitors_presence, r.inhib, at: r.at)
        product.read!(:fat_matters_concentration, r.mg, at: r.at)
        product.read!(:protein_matters_concentration, r.mp, at: r.at)
        product.read!(:somatic_cell_concentration, r.cells, at: r.at)
        product.read!(:clostridial_spores_concentration, r.buty, at: r.at)
        product.read!(:freezing_point_temperature, r.cryo, at: r.at)
        product.read!(:lipolysis, r.lipo, at: r.at)
        product.read!(:immunoglobulins_concentration, r.igg, at: r.at)
        product.read!(:urea_concentration, r.uree, at: r.at)

        w.check_point
      end
    end
  end
end
