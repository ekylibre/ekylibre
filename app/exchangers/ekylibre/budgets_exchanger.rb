module Ekylibre
  class BudgetsExchanger < ActiveExchanger::Base
    ACTIVITIES = {
      tool_maintaining: %i[maintenance equipment_management],
      administering: %i[accountancy sales purchases stocks exploitation],
      service_delivering: %i[animal_housing catering lodging renting agricultural_works building_works works],
      animal_farming: %i[beekeeping cattle_farming bison_farming goat_farming ostrich_farming oyster_farming palmiped_farming pig_farming poultry_farming rabbit_farming salmon_farming scallop_farming sheep_farming snail_farming sturgeon_farming mussel_farming],
      plant_farming: %i[vegetal_crops alfalfa_crops almond_orchards apple_orchards arboriculture aromatic_and_medicinal_plants artichoke_crops asparagus_crops avocado_crops barley_crops bean_crops beet_crops bere_crops black_mustard_crops blackcurrant_crops cabbage_crops canary_grass_crops carob_orchards carrot_crops celery_crops cereal_crops chestnut_orchards chickpea_crops chicory_crops cichorium_crops citrus_orchards cocoa_crops common_wheat_crops cotton_crops durum_wheat_crops eggplant_crops fallow_land field_crops flax_crops flower_crops fodder_crops fruits_crops garden_pea_crops garlic_crops hazel_orchards hemp_crops hop_crops horsebean_crops lavender_crops leek_crops leguminous_crops lentil_crops lettuce_crops lupin_crops maize_crops market_garden_crops meadow muskmelon_crops oat_crops oilseed_crops olive_groves olive_orchards onion_crops parsley_crops pea_crops peach_orchards peanut_crops pear_orchards pineapple_crops pistachio_orchards plum_orchards poaceae_crops potato_crops protein_crops radish_crops rapeseed_crops raspberry_crops redcurrant_crops rice_crops rye_crops saffron_crops sorghum_crops soybean_crops strawberry_crops sunflower_crops tobacco_crops tomato_crops triticale_crops turnip_crops vetch_crops vines walnut_orchards watermelon_crops]
    }.freeze

    def import
      s = Roo::OpenOffice.new(file)
      w.count = s.sheets.count

      s.sheets.each do |sheet_name|
        s.sheet(sheet_name)

        # get information for production context
        campaign_harvest_year = s.cell('A', 2).to_i
        activity_name = (s.cell('B', 2).blank? ? nil : s.cell('B', 2).to_s.strip)
        # activity_name[0] : activity_name, ex : 'Les papiers'
        # activity_name[1] : Nomen::ActivityFamily code, ex : administrative
        activity_family = (s.cell('C', 2).blank? ? nil : s.cell('C', 2).to_s.strip)
        activity_variety = (s.cell('D', 2).blank? ? nil : s.cell('D', 2).to_s.strip)
        # production_support_numbers[0] : support number, ex : ZC32
        # production_support_numbers[1] : quantity, ex : 1.52
        # production_support_numbers could be ZC32:1.5, ZC33
        cultivation_variant_reference_name = s.cell('E', 2)
        support_variant_reference_name = s.cell('F', 2).to_s.strip
        support_variant_reference_name = nil if support_variant_reference_name.blank?
        production_indicator = (s.cell('G', 2).blank? ? [] : s.cell('G', 2).to_s.strip.downcase.delete(' ').split('/'))

        # get budget concerning production (activty / given campaign)
        campaign = Campaign.find_or_create_by!(harvest_year: campaign_harvest_year)

        # get activity by name or variety
        activity = Activity.find_by(name: activity_name)
        unless activity
          if activity_name && activity_family
            family = Nomen::ActivityFamily.find(activity_family.to_sym)
            variety = Nomen::Variety.find(activity_variety.to_sym) if activity_variety
            if family
              # create activity

              attributes = {
                name: activity_name,
                family: activity_family,
                cultivation_variety: activity_variety,
                with_cultivation: true,
                production_cycle: :annual,
                nature: :main
              }
              if activity_variety && family <= :plant_farming
                attributes.update(
                  family: :plant_farming,
                  cultivation_variety: activity_variety,
                  support_variety: :cultivable_zone,
                  with_supports: true,
                  size_indicator: 'net_surface_area',
                  size_unit: 'hectare'
                )
              elsif activity_variety && family <= :animal_farming
                attributes.update(
                  family: :animal_farming,
                  cultivation_variety: activity_variety,
                  support_variety: :animal_group,
                  with_supports: true,
                  size_indicator: 'members_population'
                )
              elsif family <= :administering
                attributes.update(
                  family: :administering,
                  with_cultivation: false,
                  with_supports: false,
                  cultivation_variety: nil,
                  support_variety: nil,
                  nature: :auxiliary
                )
              end

              activity = Activity.find_or_initialize_by(attributes.slice(:name, :family, :cultivation_variety))
              activity.attributes = attributes
              activity.save!

            else
              raise ActiveExchanger::Error, 'You must mention correct nomen element'
            end
          else
            raise ActiveExchanger::Error, "You must mention activity attributes to create it : activity name : #{activity_name}, activity family : #{activity_family}, activity variety : #{activity_variety}"
          end
        end

        w.info "Sheet: #{sheet_name} "

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
          computation_method = case s.cell('C', row_number).to_s.downcase
                                 when 'uo' then :per_working_unit
                                 when 'support' then :per_production
                                 when 'production' then :per_production
                                 else :per_working_unit
                               end
          r = {
            item_name: s.cell('A', row_number),
            item_code_variant: s.cell('B', row_number),
            computation_method: computation_method,
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
            unless item_variant = ProductNatureVariant.find_by(work_number: r.item_code_variant) ||
                                  ProductNatureVariant.find_by(reference_name: r.item_code_variant)
              if Nomen::ProductNatureVariant[r.item_code_variant]
                item_variant = ProductNatureVariant.import_from_nomenclature(r.item_code_variant)
              else
                w.error "No variant could be created with #{r.item_code_variant}"
                next
              end
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
              raise ActiveExchanger::NotWellFormedFileError, "Unknown unit #{unit.inspect} for variant #{item_variant.name.inspect}."
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
                raise ActiveExchanger::NotWellFormedFileError, "Ambiguity on unit #{unit.inspect} for variant #{item_variant.name.inspect} between #{indics.to_sentence(locale: :eng)}. Cannot known what is wanted, insert indicator name after unit like: '#{unit} (#{indics.first})'."
              end
            elsif indics.empty?
              if unit == 'hour'
                indicator = 'usage_duration'
              else
                raise ActiveExchanger::NotWellFormedFileError, "Unit #{unit.inspect} is invalid for variant #{item_variant.name.inspect}. No indicator can be used with this unit."
              end
            else
              indicator = indics.first
            end
          end

          unless r.item_unit_price_amount
            raise ActiveExchanger::NotWellFormedFileError, "No price given for #{r.item_name}"
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

    protected

    def transcode_activity_family(activity_family)
      results = ACTIVITIES.select do |_k, v|
        v.include?(activity_family)
      end
      results.keys.first
    end
  end
end
