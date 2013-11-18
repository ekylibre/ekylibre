demo :analyses do

  Ekylibre::fixturize :milk_production_analysis_import do |w|

    #############################################################################
    # import Milk result to make automatic quality indicators
    # @TODO
    #
    # add a product_nature
    product_nature_variant = ProductNatureVariant.import_from_nomenclature(:cow_milk)

    # create a generic product to link analysis_indicator
    product   = OrganicMatter.find_by_name("lait_vache")
    product ||= OrganicMatter.create!( :variant_id => product_nature_variant.id, :name => "lait_vache", :identification_number => "MILK_FR_1997-2013", :work_number => "lait_2013", :born_at => Time.now, :initial_owner_id => Entity.of_company.id, :default_storage => Equipment.find_by_name("Tank"))

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
end
