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
      :storage_work_number => row[5].blank? ? nil : row[5].to_s,
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


    name = (r.name.blank? ? r.production_nature.human_name : r.name)
    attributes = {
      nature: r.nature,
      family: activity_family.name,
      name: name
    }
    if activity = Activity.find_by(attributes.slice(:name))
      i = 0
      while activity.family.to_s != activity_family.name.to_s do
        i += 1
        attributes[:name] = name + " (#{i})"
        unless activity = Activity.find_by(attributes.slice(:name))
          activity = Activity.create!(attributes)
        end
      end
    else
      activity = Activity.create!(attributes)
    end

    # if a variant_reference_name is present
    cultivation_variant = nil
    if r.variant
      # Import from nomen with r.variant_reference_name in file
      cultivation_variant = ProductNatureVariant.import_from_nomenclature(r.variant.name)
    elsif r.production_nature.variant_support
      # Import from nomen with item of ProductionNature
      cultivation_variant = ProductNatureVariant.import_from_nomenclature(r.production_nature.variant_support.to_s)
    end

    w.debug "Activity: #{activity.name}"

    if cultivation_variant
      w.debug "ProductNatureVariant: #{cultivation_variant.name}"

      # Find or create a production
      attrs = {campaign: campaign, activity: activity, cultivation_variant: cultivation_variant, name: r.name}
      if activity.with_supports
        unless attrs[:support_variant] = ProductNatureVariant.of_variety(activity.support_variety).first
          variety = Nomen::Varieties[activity.support_variety]
          item = Nomen::ProductNatureVariants.list.select{|i| i.variety.present? and variety >= i.variety }.sample
          attrs[:support_variant] = ProductNatureVariant.import_from_nomenclature(item.name)
        end
      end
      unless production = Production.find_by(attrs.slice(:name))
        production = Production.create!(attrs)
      end
      w.debug "Production: #{production.name}"

      production.state = :opened
      # and create a support for this production
      production.started_at ||= r.started_at
      production.stopped_at ||= r.stopped_at
      if r.cultivation_nature == "nitrat_trap" or r.cultivation_nature == "nitrate_fixing"
        production.nitrate_fixing = true
      end
      # Find storage
      if storage = Product.find_by(work_number: r.storage_work_number)
        unless production.supports.find_by(storage: storage)
          support = production.supports.create!(storage: storage, production_usage: r.production_usage)
        end
      end
      # if the support is a CultivableZone
      if r.irrigated
        production.irrigated = true
      end
      # Create mass_area_yield_markers
      # @FIXME Remove column or use budget in place of markers
      # for derivative, value in r.mass_area_yield_markers
      #   support.read!(:mass_area_yield, value, derivative: derivative)
      # end

      # Create standard support_markers
      # @FIXME Remove column or use budget in place of markers
      # for indicator, value in r.support_markers
      #   support.read!(indicator, value)
      # end

      production.state = (campaign.closed? ? :closed : :opened)
      production.save!
    end

    w.check_point
  end


end
