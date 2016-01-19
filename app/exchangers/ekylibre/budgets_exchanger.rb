# coding: utf-8
module Ekylibre
  class BudgetsExchanger < ActiveExchanger::Base
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
        cultivation_variety = nil

        if cultivation_variant_reference_name
          if cultivation_variety = Nomen::Variety.find(cultivation_variant_reference_name.to_sym)
            w.info 'cultivation_variant_reference_name is a variety'
          elsif cultivation_variant = ProductNatureVariant.find_by(number: cultivation_variant_reference_name) || ProductNatureVariant.find_by(reference_name: cultivation_variant_reference_name)
            w.info 'cultivation_variant_reference_name is an existing variant in DB'
          elsif cultivation_variant = ProductNatureVariant.import_from_nomenclature(cultivation_variant_reference_name)
            w.info 'cultivation_variant_reference_name is an existing variant in NOMENCLATURE and will be imported'
          elsif cultivation_variant.nil?
            w.error "cultivation_variant_reference_name #{cultivation_variant_reference_name}.inspect is not a variant neither a variety"
          end
        end

        cultivation_variety ||= cultivation_variant.variety if cultivation_variant

        if support_variant_reference_name
          unless support_variant = ProductNatureVariant.find_by(number: support_variant_reference_name) || ProductNatureVariant.find_by(reference_name: support_variant_reference_name)
            support_variant = ProductNatureVariant.import_from_nomenclature(support_variant_reference_name)
          end
        end

        # find or create activity
        unless activity = Activity.find_by(name: activity_name[0].strip)
          family = if activity_name[1]
                     Nomen::ActivityFamily[activity_name[1].strip]
                   else
                     Activity.find_best_family((cultivation_variety ? cultivation_variety : nil), (support_variant ? support_variant.variety : nil))
                   end
          unless family
            w.error 'Cannot determine activity'
            fail ActiveExchanger::Error, "Cannot determine activity with support #{support_variant ? support_variant.variety.inspect : '?'} and cultivation #{cultivation_variant ? cultivation_variant.variety.inspect : '?'} in production #{sheet_name}"
          end
          activity = Activity.new(
            name: activity_name[0].strip,
            family: family.name,
            size_indicator: (production_indicator[0] ? production_indicator[0].strip.to_sym : nil),
            size_unit: (production_indicator[1] ? production_indicator[1].strip.to_sym : nil),
            nature: family.nature,
            with_supports: (production_support_numbers.any? ? true : false),
            production_cycle: :annual
          )
          if support_variant && support_variant.variety
            activity.support_variety = (Nomen::Variety.find(support_variant.variety) == :cultivable_zone ? :cultivable_zone : (Nomen::Variety.find(support_variant.variety) <= :building_division ? :building_division : :product))
            activity.with_cultivation = (Nomen::Variety.find(support_variant.variety) == :cultivable_zone ? true : false)
          end
          activity.cultivation_variety = cultivation_variety if cultivation_variant
          activity.save!
        end

        w.info "Sheet: #{sheet_name} (#{cultivation_variant})"

        # find or create activity production

        production_support_numbers.each do |number|
          # get quantity and number given
          arr = nil
          arr = number.to_s.strip.delete(' ').split(':')

          production_support_number = arr[0]
          production_support_quantity = arr[1]

          if product = Product.find_by(number: production_support_number) || Product.find_by(identification_number: production_support_number) || Product.find_by(work_number: production_support_number)
            # puts 'Product exist'.inspect.yellow
            if product.shape
              cz = CultivableZone.shape_covering(product.shape, 0.02).first
            end
          elsif cz = CultivableZone.find_by(work_number: production_support_number)
            product = LandParcel.shape_covering(cz.shape, 0.02).first
            unless product
              lp_variant = ProductNatureVariant.import_from_nomenclature(:land_parcel)
              product = LandParcel.create!(variant: lp_variant, work_number: cz.work_number,
                                           name: cz.work_number, initial_born_at: Time.now, initial_owner: Entity.of_company, initial_shape: cz.shape)
            end
          # puts product.inspect.red
          # puts 'Cultivable zone exist'.inspect.yellow
          else
            puts "Cannot find support with number: #{number.inspect}".inspect.yellow
          end

          w.info 'No Product given for ' unless product

          attributes = {
            activity: activity,
            support: product,
            started_on: Date.new(campaign.harvest_year - 1, 10, 1),
            stopped_on: Date.new(campaign.harvest_year, 8, 1),
            state: :opened,
            campaign_id: campaign.id
          }

          if activity.with_supports && cz && product && product.shape && Nomen::ActivityFamily[activity.family] <= :vegetal_crops
            attributes[:cultivable_zone] = cz
            attributes[:support_shape] = product.shape
            attributes[:size] = ::Charta.new_geometry(product.shape).area.in(:hectare)
            attributes[:usage] = :grain
          elsif activity.with_supports && Nomen::Variety.find(:animal_group) == support_variant.variety.to_sym
            attributes[:size_value] = 1.0
            attributes[:usage] = :meat
          else
            attributes[:size_indicator] = 'net_mass'
            attributes[:size_value] = 1.0
            attributes[:usage] = :grain
          end
          unless ap = ActivityProduction.find_by(activity: activity, support: product)
            ap = ActivityProduction.create!(attributes)
            td = TargetDistribution.find_or_create_by!(activity: activity, activity_production: ap, target: product) if Nomen::ActivityFamily[activity.family] <= :vegetal_crops
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

        activity_budget = ActivityBudget.find_or_create_by!(campaign: campaign, activity: activity)

        # 3 first line are not budget items
        4.upto(s.last_row) do |row_number|
          next if s.cell('A', row_number).blank?
          r = {
            item_code_variant: s.cell('B', row_number),
            computation_method: (s.cell('C', row_number).to_s.casecmp('uo') ? :per_working_unit : (s.cell('C', row_number).to_s.casecmp('support') ? :per_production : :per_campaign)),
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

          activity_budget_items = activity_budget.items.find_or_initialize_by(variant: item_variant, unit_amount: r.item_unit_price_amount)
          activity_budget_items.variant_unit = unit
          activity_budget_items.variant_indicator = indicator
          activity_budget_items.direction = r.item_direction
          activity_budget_items.computation_method = r.computation_method
          activity_budget_items.quantity = r.item_quantity if r.item_quantity
          # activity_budget_items.unit_population = r.item_quantity_unity if r.item_quantity_unity
          activity_budget_items.save!
        end
        w.check_point
      end
    end
  end
end
