# -*- coding: utf-8 -*-
load_data :productions do |loader|

  #############################################################################

  # attributes to map family
  families = {
    "CEREA" => :straw_cereal_crops,
    "COPLI" => :oilseed_crops,
    "CUFOU" => :meadow,
    "ANIMX" => :cattle_farming,
    "VIGNE" => :vine_wine,
    # "XXXXX" => :none,
    # "NINCO" => :none
  }
  # attributes to map family by activity name
  families_by_activity_name = {
    "Orge hiver" => :straw_cereal_crops,
    "Orge printemps" => :straw_cereal_crops,
    "Blé tendre" => :straw_cereal_crops,
    "Blé dur" => :straw_cereal_crops,
    "Maïs sec" => :maize_crops,
    "Triticale" => :straw_cereal_crops,
    "Jachère annuelle" => :fallow_land,
    "Tournesol" => :oilseed_crops,
    "Sorgho" => :meadow,
    "Prairie temporaire et artificielle" => :meadow,
    "Bovins lait" => :cattle_farming,
    "Veau 8-15 J" => :cattle_farming,
    "Vigne" => :vine_wine,
    "Taurillons lait" => :cattle_farming,
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


  file = loader.path("activities.csv")
  if file.exist?
    loader.count :activities_import do |w|
      # Load file
      CSV.foreach(file, :encoding => "UTF-8", :col_sep => ",", :headers => true, :quote_char => "'") do |row|
        r = OpenStruct.new(:description => row[0],
                           :name => row[1].downcase.capitalize,
                           :family => families_by_activity_name[row[1]],
                           :variant_reference_name => row[3].blank? ? nil :row[3].to_sym,
                           :nature => (natures[row[4]] || :none).to_s,
                           :campaign_harvest_year => row[5].blank? ? nil : row[5].to_i,
                           :work_number_storage => row[6].blank? ? nil : row[6].to_s,
                           :provisional_grain_yield => row[7].blank? ? nil : row[7].to_d,
                           :provisional_nitrogen_input => row[8].blank? ? nil : row[8].to_d
                           )

        # Create a campaign if not exist
        if r.campaign_harvest_year.present?
          campaign = Campaign.find_by(harvest_year: r.campaign_harvest_year)
          campaign ||= Campaign.create!(harvest_year: r.campaign_harvest_year, closed: false)
        end
        # Create an activity if not exist
        activity   = Activity.find_by(description: r.description)
        activity ||= Activity.create!(:nature => r.nature, :family => r.family, :name => r.name, :description => r.description)
        if r.variant_reference_name
          product_nature_variant_sup = ProductNatureVariant.import_from_nomenclature(r.variant_reference_name)
          product_support = Product.find_by(work_number: r.work_number_storage) || nil
          if product_nature_variant_sup and !product_support.nil?
            # find a production corresponding to campaign , activity and product_nature
            pro = Production.where(:campaign_id => campaign.id, :activity_id => activity.id, :variant_id => product_nature_variant_sup.id).first
            # or create it
            pro ||= activity.productions.create!(:variant_id => product_nature_variant_sup.id, :campaign_id => campaign.id, :static_support => true)
            # create a support for this production
            support = pro.supports.create!(:storage_id => product_support.id)
            if product_support.is_a?(CultivableZone)
              # create markers for yield and nitrogen
              if !r.provisional_grain_yield.nil?
                support.markers.create!(:indicator_name => :grain_yield_per_area, :aim => :perfect, :measure_value => r.provisional_grain_yield.in_quintal_per_hectare, :subject => :derivative, :derivative => :grain)
              end
              if !r.provisional_nitrogen_input.nil?
                support.markers.create!(:indicator_name => :nitrogen_input_per_area, :aim => :perfect, :measure_value => r.provisional_nitrogen_input.in_kilogram_per_hectare)
              end
            end
          elsif !product_nature_variant_sup.nil?
            pro = Production.where(:variant_id => product_nature_variant_sup.id, :campaign_id => campaign.id, :activity_id => activity.id).first
            pro ||= activity.productions.create!(:variant_id => product_nature_variant_sup.id, :campaign_id => campaign.id)
          end
        end
        w.check_point
      end
    end
  end

end
