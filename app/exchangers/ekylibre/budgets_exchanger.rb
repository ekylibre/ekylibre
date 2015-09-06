# coding: utf-8
class Ekylibre::BudgetsExchanger < ActiveExchanger::Base
  def import
    s = Roo::OpenOffice.new(file)
    w.count = s.sheets.count

    s.sheets.each do |sheet_name|
      s.sheet(sheet_name)

      # get information for production context
      campaign_harvest_year = s.cell('A', 2).to_i
      activity_name = (s.cell('B', 2).blank? ? [] : s.cell('B', 2).to_s.strip.split('/'))
      # activity_name[0] : activity_name, ex : 'Les papiers'
      # activity_name[1] : Nomen::ActivityFamily code, ex : administrative
      production_name = s.cell('C', 2)
      production_support_numbers = (s.cell('D', 2).blank? ? [] : s.cell('D', 2).to_s.strip.upcase.split(/[\s\,]+/))
      # production_support_numbers[0] : support number, ex : ZC32
      # production_support_numbers[1] : quantity, ex : 1.52
      # production_support_numbers could be ZC32:1.5, ZC33
      cultivation_variant_reference_name = s.cell('E', 2)
      support_variant_reference_name = s.cell('F', 2).to_s.strip
      support_variant_reference_name = nil if support_variant_reference_name.blank?
      production_indicator = (s.cell('G', 2).blank? ? [] : s.cell('G', 2).to_s.strip.downcase.delete(' ').split('/'))

      # get budget concerning production (activty / given campaign)
      campaign = Campaign.find_or_create_by!(harvest_year: campaign_harvest_year)
      cultivation_variant = nil

      if cultivation_variant_reference_name
        unless cultivation_variant = ProductNatureVariant.find_by(number: cultivation_variant_reference_name) || ProductNatureVariant.find_by(reference_name: cultivation_variant_reference_name)
          cultivation_variant = ProductNatureVariant.import_from_nomenclature(cultivation_variant_reference_name)
        end
      end

      if support_variant_reference_name
        unless support_variant = ProductNatureVariant.find_by(number: support_variant_reference_name) || ProductNatureVariant.find_by(reference_name: support_variant_reference_name)
          support_variant = ProductNatureVariant.import_from_nomenclature(support_variant_reference_name)
        end
      end

      unless activity = Activity.find_by(name: activity_name[0].strip)
        if activity_name[1]
          family = Nomen::ActivityFamily[activity_name[1].strip]
        else
          family = Activity.find_best_family((cultivation_variant ? cultivation_variant.variety : nil), (support_variant ? support_variant.variety : nil))
        end
        unless family
          w.error 'Cannot determine activity'
          fail ActiveExchanger::Error, "Cannot determine activity with support #{support_variant ? support_variant.variety.inspect : '?'} and cultivation #{cultivation_variant ? cultivation_variant.variety.inspect : '?'} in production #{sheet_name}"
        end
        activity = Activity.create!(name: activity_name[0].strip, family: family.name, nature: family.nature)
      end

      w.debug "Production: #{sheet_name} (#{cultivation_variant})"
      attributes = {
        campaign: campaign,
        activity: activity,
        name: production_name,
        cultivation_variant: cultivation_variant,
        support_variant: support_variant,
        started_at: Date.new(campaign.harvest_year - 1, 10, 1),
        stopped_at: Date.new(campaign.harvest_year, 8, 1),
        state: :opened
      }
      if activity.with_supports && support_variant && Nomen::Variety.find(:cultivable_zone) <= support_variant.variety
        attributes[:support_variant_indicator] = :net_surface_area
        attributes[:support_variant_unit] = :hectare
      end

      unless production = Production.find_by(attributes.slice(:name, :campaign)) # || Production.find_by(attributes.slice(:campaign, :activity, :cultivation_variant))
        production = Production.create! attributes
      end

      if production.support_variant.blank? && support_variant
        production.support_variant = support_variant
      end
      if production_indicator[0] && (production.support_variant_indicator.blank? || production.support_variant_indicator != production_indicator[0].strip.to_sym)
        production.support_variant_indicator = production_indicator[0].strip.to_sym
      end
      if production_indicator[1] && (production.support_variant_unit.blank? || production.support_variant_unit != production_indicator[1].strip.to_sym)
        production.support_variant_unit = production_indicator[1].strip.to_sym
      end
      production.save!

      # Create support if doesn't exist ?
      production_support_numbers.each do |number|
        # get quantity and number given
        arr = nil
        arr = number.to_s.strip.delete(' ').split(':')
        production_support_number = arr[0]
        production_support_quantity = arr[1]
        if product = Product.find_by(number: production_support_number) || Product.find_by(identification_number: production_support_number) || Product.find_by(work_number: production_support_number)
          ps = production.supports.find_or_create_by!(storage_id: product.id)
        else
          w.warn "Cannot find support with number: #{number.inspect}"
        end
        if production_support_quantity
          ps.quantity = production_support_quantity
          ps.save!
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
            unless Nomen::ProductNatureVariant[r.item_code_variant]
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
        if unit.present? && !Nomen::Unit[unit]
          if u = Nomen::Unit.find_by(symbol: unit)
            unit = u.name.to_s
          else
            fail ActiveExchanger::NotWellFormedFileError, "Unknown unit #{unit.inspect} for variant #{item_variant.name.inspect}."
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
              fail ActiveExchanger::NotWellFormedFileError, "Ambiguity on unit #{unit.inspect} for variant #{item_variant.name.inspect} between #{indics.to_sentence(locale: :eng)}. Cannot known what is wanted, insert indicator name after unit like: '#{unit} (#{indics.first})'."
            end
          elsif indics.empty?
            if unit == 'hour'
              indicator = 'working_duration'
            else
              fail ActiveExchanger::NotWellFormedFileError, "Unit #{unit.inspect} is invalid for variant #{item_variant.name.inspect}. No indicator can be used with this unit."
            end
          else
            indicator = indics.first
          end
        end

        # Set budget
        budget = production.budgets.find_or_initialize_by(variant: item_variant, direction: r.item_direction, computation_method: r.computation_method)
        budget.variant_unit      = unit
        budget.variant_indicator = indicator
        budget.unit_currency     = :EUR
        budget.unit_amount       = r.item_unit_price_amount
        budget.quantity          = r.item_quantity
        budget.save!
      end
      w.check_point
    end
  end
end
