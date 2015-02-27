Exchanges.add_importer :ekylibre_activities do |file, w|

  rows = CSV.read(file, headers: true).delete_if{|r| r[0].blank?}
  w.count = rows.size

  rows.each_with_index do |row, index|
    w.debug "Row: #{index + 1}"
    r = {
      :production_nature => Nomen::ProductionNatures[row[0]],
      name: row[1].blank? ? nil : row[1].to_s,
      :variant => Nomen::ProductNatureVariants[row[2]],
      :nature => (row[3].blank? ? :main : row[3].to_sym || :none),
      :campaign_harvest_year => row[4].blank? ? nil : row[4].to_i,
      :work_number_storage => row[5].blank? ? nil : row[5].to_s,
      :started_at => (row[6].blank? ? Date.civil(2000, 2, 2) : row[6]).to_datetime,
      :stopped_at => (row[7].blank? ? Date.civil(2000, 2, 2) : row[7]).to_datetime,
      :irrigated => (row[8].to_s.to_i > 0),
      :cultivation_nature => (row[9].blank? ? :main : row[9].to_sym),
      :production_usage => (row[10].blank? ? :grain : row[10].to_sym),
      :mass_area_yield_markers => row[11].blank? ? {} : row[11].to_s.strip.split(/[[:space:]]*\;[[:space:]]*/).collect{|i| i.split(/[[:space:]]*\:[[:space:]]*/)}.inject({}) { |h, i|
        h[i.first.strip.downcase.to_sym] = i.second
        h
      },
      :support_markers => row[12].blank? ? {} : row[12].to_s.strip.split(/[[:space:]]*\;[[:space:]]*/).collect{|i| i.split(/[[:space:]]*\:[[:space:]]*/)}.inject({}) { |h, i|
        h[i.first.strip.downcase.to_sym] = i.second
        h
      }
    }.to_struct

    # Create a campaign if not exist
    unless r.campaign_harvest_year.present?
      raise Exchanges::Error, "No campaign given"
    end

    # Get campaign
    unless campaign = Campaign.find_by(harvest_year: r.campaign_harvest_year)
      campaign = Campaign.create!(harvest_year: r.campaign_harvest_year, closed: false)
    end

    # Create an activity if not exist with production_code
    unless activity_family = Nomen::ActivityFamilies[r.production_nature.activity]
      raise Exchanges::Error, "No activity family. (#{r.inspect})"
    end

    activity = Activity.find_or_create_by!(nature: r.nature, family: activity_family.name, name: (r.name.blank? ? r.production_nature.human_name : r.name))

    # if a variant_reference_name is present
    product_nature_variant = nil
    if r.variant
      # Import from nomen with r.variant_reference_name in file
      product_nature_variant = ProductNatureVariant.import_from_nomenclature(r.variant.name)
    elsif r.production_nature.variant_support
      # Import from nomen with item of ProductionNature
      product_nature_variant = ProductNatureVariant.import_from_nomenclature(r.production_nature.variant_support.to_s)
    end

    w.debug "Activity: #{activity.name}"

    if product_nature_variant
      w.debug "ProductNatureVariant: #{product_nature_variant.name}"
      # Find or create a production
      production = Production.find_or_create_by!(campaign_id: campaign.id, activity_id: activity.id, producing_variant_id: product_nature_variant.id, name: r.name)
      w.debug "Production: #{production.name}"

      production.state = :opened
      # Find a product
      if product_support = Product.find_by(work_number: r.work_number_storage) || nil
        # and create a support for this production
        production.started_at ||= r.started_at
        production.stopped_at ||= r.stopped_at
        if r.cultivation_nature == "nitrat_trap" or r.cultivation_nature == "nitrate_fixing"
          production.nitrate_fixing = true
        end
        support = production.supports.create!(storage_id: product_support.id, production_usage: r.production_usage)
        # if the support is a CultivableZone
        if product_support.is_a?(CultivableZone)
          if r.irrigated
            production.irrigated = true
          end
          # Create mass_area_yield_markers
          # @FIXME Remove column or use budget in place of markers
          # for derivative, value in r.mass_area_yield_markers
          #   support.read!(:mass_area_yield, value, derivative: derivative)
          # end
        end

        # Create standard support_markers
        # @FIXME Remove column or use budget in place of markers
        # for indicator, value in r.support_markers
        #   support.read!(indicator, value)
        # end

      end
      production.state = (campaign.closed? ? :closed : :opened)
      production.save!
    end

    w.check_point
  end


end
