# -*- coding: utf-8 -*-
load_data :productions do |loader|

  #############################################################################

  file = loader.path("alamano", "activities.csv")
  if file.exist?
    loader.count :activities_import do |w|
      # Load file
      CSV.foreach(file, :encoding => "UTF-8", :col_sep => ",", :headers => true, :quote_char => "'") do |row|
        next if row[0].blank?
        r = OpenStruct.new(:production_nature => Nomen::ProductionNatures[row[0].to_sym],
                           :name => row[1].blank? ? nil : row[1].to_s,
                           :variant_reference_name => row[2].blank? ? nil : row[2].to_sym,
                           :nature => (row[3].blank? ? :main : row[3].to_sym || :none),
                           :campaign_harvest_year => row[4].blank? ? nil : row[4].to_i,
                           :work_number_storage => row[5].blank? ? nil : row[5].to_s,
                           :started_at => (row[6].blank? ? Date.civil(2000, 2, 2) : row[6]).to_datetime,
                           :stopped_at => (row[7].blank? ? Date.civil(2000, 2, 2) : row[7]).to_datetime,
                           :yield_indicators => row[8].blank? ? {} : row[8].to_s.strip.split(/[[:space:]]*\;[[:space:]]*/).collect{|i| i.split(/[[:space:]]*\:[[:space:]]*/)}.inject({}) { |h, i|
                             h[i.first.strip.downcase.to_sym] = i.second
                             h
                           },
                           :indicators => row[9].blank? ? {} : row[9].to_s.strip.split(/[[:space:]]*\;[[:space:]]*/).collect{|i| i.split(/[[:space:]]*\:[[:space:]]*/)}.inject({}) { |h, i|
                             h[i.first.strip.downcase.to_sym] = i.second
                             h
                           }                           
                           )

        # Create a campaign if not exist
        if r.campaign_harvest_year.present?
          campaign = Campaign.find_by(harvest_year: r.campaign_harvest_year)
          campaign ||= Campaign.create!(harvest_year: r.campaign_harvest_year, closed: false)
        end
        
        #create an activity if not exist with production_code
        activity_family_item = Nomen::ActivityFamilies[r.production_nature.activity]
        unless activity = Activity.find_by(:nature => r.nature, family: activity_family_item.name)  
          activity = Activity.create!(:nature => r.nature, :family => activity_family_item.name, :name => (r.name ? r.production_nature.human_name : r.name))
        end
        
        # if a variant_reference_name is present
        if r.variant_reference_name
          # import from nomen with r.variant_reference_name in file
          product_nature_variant = ProductNatureVariant.import_from_nomenclature(r.variant_reference_name)
        elsif r.production_nature.variant_support
          # import from nomen with item of ProductionNature
          product_nature_variant = ProductNatureVariant.import_from_nomenclature(r.production_nature.variant_support.to_s)
        end
        
        if product_nature_variant
          # find or create a production
          production = Production.where(campaign_id: campaign.id, activity_id: activity.id, variant_id: product_nature_variant.id).first
          production ||= activity.productions.create!(variant_id: product_nature_variant.id, campaign_id: campaign.id)
          # find a product
          product_support = Product.find_by(work_number: r.work_number_storage) || nil
          if product_support
            # if exist, this production has static_support
            production.static_support = true
            production.save!
            # and create a support for this production
            support = production.supports.create!(storage_id: product_support.id, :started_at => r.started_at, :stopped_at => r.stopped_at)
            # if the support is a CultivableZone
            if product_support.is_a?(CultivableZone)
              # create yield_indicators
              for indicator, value in r.yield_indicators
                support.read!(:mass_area_yield, value, derivative: indicator)
              end
            end
            # and create standard indicators
            for indicator, value in r.indicators
              support.read!(indicator, value)
            end
          end         
        end
        w.check_point
      end
    end
  end

end
