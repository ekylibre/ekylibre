# -*- coding: utf-8 -*-
load_data :productions do |loader|

  #############################################################################
  if loader.manifest[:create_activities_from_telepac] == false
  #
  file = loader.path("alamano", "activities.csv")
  if file.exist?
    loader.count :activities_import do |w|
      # Load file
      CSV.foreach(file, headers: true) do |row|
        next if row[0].blank?
        r = OpenStruct.new(:production_nature => Nomen::ProductionNatures[row[0]],
                           name: row[1].blank? ? nil : row[1].to_s,
                           :variant => Nomen::ProductNatureVariants[row[2]],
                           :nature => (row[3].blank? ? :main : row[3].to_sym || :none),
                           :campaign_harvest_year => row[4].blank? ? nil : row[4].to_i,
                           :work_number_storage => row[5].blank? ? nil : row[5].to_s,
                           :started_at => (row[6].blank? ? Date.civil(2000, 2, 2) : row[6]).to_datetime,
                           :stopped_at => (row[7].blank? ? Date.civil(2000, 2, 2) : row[7]).to_datetime,
                           :mass_area_yield_markers => row[8].blank? ? {} : row[8].to_s.strip.split(/[[:space:]]*\;[[:space:]]*/).collect{|i| i.split(/[[:space:]]*\:[[:space:]]*/)}.inject({}) { |h, i|
                             h[i.first.strip.downcase.to_sym] = i.second
                             h
                           },
                           :support_markers => row[9].blank? ? {} : row[9].to_s.strip.split(/[[:space:]]*\;[[:space:]]*/).collect{|i| i.split(/[[:space:]]*\:[[:space:]]*/)}.inject({}) { |h, i|
                             h[i.first.strip.downcase.to_sym] = i.second
                             h
                           }                           
                           )

        
        # Create a campaign if not exist
        unless r.campaign_harvest_year.present?
          raise "No campaign given"
        end

        # Get campaign
        unless campaign = Campaign.find_by(harvest_year: r.campaign_harvest_year)
          campaign = Campaign.create!(harvest_year: r.campaign_harvest_year, closed: false)
        end
        
        # Create an activity if not exist with production_code
        unless activity_family = Nomen::ActivityFamilies[r.production_nature.activity]
          raise "No activity family. (#{r.inspect})"          
        end

        unless activity = Activity.find_by(nature: r.nature, family: activity_family.name, name: (r.name ? r.production_nature.human_name : r.name))  
          activity = Activity.create!(nature: r.nature, family: activity_family.name, name: (r.name ? r.production_nature.human_name : r.name))
        end
        
        # if a variant_reference_name is present
        product_nature_variant = nil
        if r.variant
          # Import from nomen with r.variant_reference_name in file
          product_nature_variant = ProductNatureVariant.import_from_nomenclature(r.variant.name)
        elsif r.production_nature.variant_support
          # Import from nomen with item of ProductionNature
          product_nature_variant = ProductNatureVariant.import_from_nomenclature(r.production_nature.variant_support.to_s)
        end
        
        if product_nature_variant
          # Find or create a production
          unless production = Production.find_by(campaign_id: campaign.id, activity_id: activity.id, variant_id: product_nature_variant.id)
            production = activity.productions.create!(variant_id: product_nature_variant.id, campaign_id: campaign.id)
          end
          # Find a product
          if product_support = Product.find_by(work_number: r.work_number_storage) || nil
            # if exist, this production has static_support
            production.static_support = true
            production.save!
            # and create a support for this production
            support = production.supports.create!(storage_id: product_support.id, :started_at => r.started_at, :stopped_at => r.stopped_at)
            # if the support is a CultivableZone
            if product_support.is_a?(CultivableZone)
              # create mass_area_yield_markers
              for derivative, value in r.mass_area_yield_markers
                support.read!(:mass_area_yield, value, derivative: derivative)
              end
            end
            # and create standard support_markers
            for indicator, value in r.support_markers
              support.read!(indicator, value)
            end
          end         
        end
        w.check_point
      end
    end
  end
  end

end
