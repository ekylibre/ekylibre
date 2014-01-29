# -*- coding: utf-8 -*-
load_data :productions do |loader|

  #############################################################################

  # Collect activity family matchings
  activity_families = {}.with_indifferent_access

  file = loader.path("activity_families.csv")
  if file.exist?
    CSV.foreach(file, headers: true) do |row|
      activity_families[row[0]] = row[1].to_sym
    end
  end

  # Collect activity natures
  activity_natures = {}.with_indifferent_access

  file = loader.path("activity_natures.csv")
  if file.exist?
    CSV.foreach(file, headers: true) do |row|
      activity_natures[row[0]] = row[1].to_sym
    end
  end

  file = loader.path("activities.csv")
  if file.exist?
    loader.count :activities_import do |w|
      # Load file
      CSV.foreach(file, :encoding => "UTF-8", :col_sep => ",", :headers => true, :quote_char => "'") do |row|
        r = OpenStruct.new(:description => row[0],
                           :name => row[1].downcase.capitalize,
                           :family => activity_families[row[1]],
                           :variant_reference_name => row[3].blank? ? nil : row[3].to_sym,
                           :nature => (row[4].blank? ? :none : activity_natures[row[4]] || :none),
                           :campaign_harvest_year => row[5].blank? ? nil : row[5].to_i,
                           :work_number_storage => row[6].blank? ? nil : row[6].to_s,
                           :provisional_grain_yield => row[7].blank? ? nil : row[7].to_d,
                           :provisional_nitrogen_input => row[8].blank? ? nil : row[8].to_d,
                           :provisional_residue_elimination_method => row[9].blank? ? nil : row[9].to_sym
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
            pro = Production.where(campaign_id: campaign.id, activity_id: activity.id, variant_id: product_nature_variant_sup.id).first
            # or create it
            pro ||= activity.productions.create!(variant_id: product_nature_variant_sup.id, campaign_id: campaign.id, static_support: true)
            # create a support for this production
            support = pro.supports.create!(storage_id: product_support.id, :started_at => Date.civil(campaign.harvest_year - 1, 10, 1), :stopped_at => Date.civil(campaign.harvest_year, 9, 30))
            if product_support.is_a?(CultivableZone)
              # create markers for yield and nitrogen
              if !r.provisional_grain_yield.nil?
                support.is_measured!(:mass_area_yield, r.provisional_grain_yield.in_quintal_per_hectare, derivative: :grain)
              end
              if !r.provisional_nitrogen_input.nil?
                support.is_measured!(:nitrogen_input_area_density, r.provisional_nitrogen_input.in_kilogram_per_hectare)
              end
              if !r.provisional_residue_elimination_method.nil?
                support.markers.create!(:indicator_name => :residue_elimination_method, :aim => :perfect, :choice_value => r.provisional_residue_elimination_method)
              end
              
            end
          elsif !product_nature_variant_sup.nil?
            pro = Production.where(variant_id: product_nature_variant_sup.id, campaign_id: campaign.id, :activity_id => activity.id).first
            pro ||= activity.productions.create!(variant_id: product_nature_variant_sup.id, campaign_id: campaign.id)
          end
        end
        w.check_point
      end
    end
  end

end
