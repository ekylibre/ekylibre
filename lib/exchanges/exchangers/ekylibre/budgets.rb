# coding: utf-8
Exchanges.add_importer :ekylibre_budgets do |file, w|

  s = Roo::OpenOffice.new(file)
  w.count = s.sheets.count

  s.sheets.each do |sheet_name|
    s.sheet(sheet_name)

    # get information for production context
    campaign_harvest_year = s.cell('A', 2)
    activity_name = s.cell('B', 2)
    production_support_numbers = (s.cell('C', 2).blank? ? [] : s.cell('C', 2).to_s.strip.upcase.split(/[\s\,]+/))
    producing_variant_reference_name = s.cell('D', 2)
    production_support_variant_reference_name = s.cell('E', 2)
    production_indicator_reference_name = s.cell('F', 2)
    production_indicator_unit_reference_name = s.cell('G', 2)

    # get budget concerning production (activty / given campaign)

    activity = Activity.find_or_create_by!(name: activity_name)
    campaign = Campaign.find_or_create_by!(harvest_year: campaign_harvest_year)
    producing_variant = nil

    if producing_variant_reference_name
      unless producing_variant = ProductNatureVariant.find_by(number: producing_variant_reference_name) || ProductNatureVariant.find_by(reference_name: producing_variant_reference_name)
        producing_variant = ProductNatureVariant.import_from_nomenclature(producing_variant_reference_name)
      end
    end

    w.debug "Production: #{sheet_name}"
    production = Production.find_or_create_by!(name: sheet_name, activity: activity, campaign: campaign, producing_variant: producing_variant)

    if production_support_variant_reference_name
      unless production_support_variant = ProductNatureVariant.find_by(number: production_support_variant_reference_name) || ProductNatureVariant.find_by(reference_name: production_support_variant_reference_name)
        production_support_variant = ProductNatureVariant.import_from_nomenclature(production_support_variant_reference_name)
      end
    end

    if production.support_variant.blank? and production_support_variant
      production.support_variant = production_support_variant
    end

    if production_indicator_reference_name and (production.working_indicator.blank? || production.working_indicator != production_indicator_reference_name.to_sym)
      production.working_indicator = production_indicator_reference_name.to_sym
    end

    if production_indicator_unit_reference_name and (production.working_unit.blank? || production.working_unit != production_indicator_unit_reference_name.to_sym)
      production.working_unit = production_indicator_unit_reference_name.to_sym
    end

    production.save!


    # Create support if doesn't exist ?
    production_support_numbers.each do |number|
      if product = Product.find_by(number: number) || Product.find_by(identification_number: number) || Product.find_by(work_number: number)
        production.supports.find_or_create_by!(storage_id: product.id)
      else
        w.warn "Cannot find support with number: #{number.inspect}"
      end
    end


    # file format
    # A "Nom de l'intervention ou de intrant"
    # B "Variant reference_name CF NOMENCLATURE"
    # C "Proportionnalité" vide = support ou production_indicator_unit_reference_name
    # D "Quantité"
    # E "Unité de la quantité CF NOMENCLATURE"
    # F "Prix TTC"
    # G "sens -1 = dépense / +1 = recette"

    # 3 first line are not budget items
    4.upto(s.last_row) do |row_number|
      next if s.cell('A', row_number).blank?
      r = {
        item_code_variant: s.cell('B', row_number),
        computation_method: (s.cell('C', row_number).to_s.downcase == 'uo' ? :per_working_unit : (s.cell('C', row_number).to_s.downcase == 'support' ? :per_production_support : :per_production)),
        item_quantity: (s.cell('D', row_number).blank? ? nil : s.cell('D', row_number).to_d),
        item_quantity_unity: s.cell('E', row_number).to_s.strip.split(/[\,\.\/\\\(\)]/),
        item_unit_price_amount: (s.cell('F', row_number).blank? ? nil : s.cell('F', row_number).to_d),
        item_direction: (s.cell('G', row_number).to_f < 0 ? :expense : :revenue)
      }.to_struct

      # Get variant
      item_variant = nil
      if r.item_code_variant.blank?
        w.error "No variant given at row #{row_number}"
        next
      else
        unless item_variant = ProductNatureVariant.find_by(number: r.item_code_variant) || ProductNatureVariant.find_by(reference_name: r.item_code_variant)
          unless Nomen::ProductNatureVariants[r.item_code_variant]
            w.error "Cannot find valid variant for budget: #{r.item_code_variant.inspect.red}"
            next
          end
          item_variant = ProductNatureVariant.import_from_nomenclature(r.item_code_variant)
        end
      end

      default_indicators = {
        mass: :net_mass,
        volume: :net_volume
      }.with_indifferent_access

      # Find unit and matching indicator
      unit = r.item_quantity_unity.first
      if unit.present? and !Nomen::Units[unit]
        if u = Nomen::Units.find_by(symbol: unit)
          unit = u.name.to_s
        else
          raise Exchanges::NotWellFormedFileError, "Unknown unit #{unit.inspect} for variant #{item_variant.name.inspect}."
        end
      end
      unless indicator = (unit.blank? ? :population : r.item_quantity_unity.second)
        dimension = Measure.dimension(unit)
        indics = item_variant.indicators.select do |indicator|
          next unless indicator.datatype == :measure
          Measure.dimension(indicator.unit) == dimension
        end.map(&:name)
        if indics.count > 1
          if indics.include?(default_indicators[dimension].to_s)
            indicator = default_indicators[dimension]
          else
            raise Exchanges::NotWellFormedFileError, "Ambiguity on unit #{unit.inspect} for variant #{item_variant.name.inspect} between #{indics.to_sentence(locale: :eng)}. Cannot known what is wanted, insert indicator name after unit like: '#{unit} (#{indics.first})'."
          end
        elsif indics.empty?
          if unit == "hour"
            indicator = "working_duration"
          else
            raise Exchanges::NotWellFormedFileError, "Unit #{unit.inspect} is invalid for variant #{item_variant.name.inspect}. No indicator can be used with this unit."
          end
        else
          indicator = indics.first
        end
      end

      # Set budget
      budget = production.budgets.find_or_initialize_by(variant: item_variant, direction: r.item_direction, computation_method: r.computation_method)
      budget.unit_currency  = :EUR
      budget.unit_unit      = unit
      budget.unit_indicator = indicator
      budget.unit_amount    = r.item_unit_price_amount
      budget.quantity       = r.item_quantity
      budget.save!

    end
    w.check_point
  end


end
