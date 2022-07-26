# frozen_string_literal: true

module TechnicalItineraries
  module Itk
    class CreateBudget
      attr_reader :activity, :campaign

      def initialize(activity:, scenario:, campaign:)
        @activity = activity
        @scenario = scenario
        @campaign = campaign
        @activity_tactic = ActivityTactic.find_by(activity: @activity, default: true)
        @logger ||= Logger.new(File.join(Rails.root, 'log', "itk-#{@campaign.name}-#{Ekylibre::Tenant.current.to_s}.log"))
      end

      def create_plot_activity_for_scenario
        # check if activity is annual / perennial and has ITK
        ti = @activity_tactic.technical_itinerary if @activity_tactic
        if @activity.annual? && ti
          # compute default area with campaign, N-1 or N-2
          current_area = @activity.size_during(@campaign).to_f
          previous_area = (@campaign.preceding ? @activity.size_during(@campaign.preceding).to_f : 0.0)
          ante_previous_area = (@campaign.preceding&.preceding ? @activity.size_during(@campaign.preceding.preceding).to_f : 0.0)
          if current_area > 0.0
            area = current_area
          elsif previous_area > 0.0
            area = previous_area
          elsif ante_previous_area > 0.0
            area = ante_previous_area
          else
            area = 0.0
          end

          # link activity and scenario
          sa = ScenarioActivity.find_or_create_by(scenario: @scenario, activity: @activity)
          # create one plot for all activity
          sap = ScenarioActivity::Plot.find_or_initialize_by(scenario_activity: sa)
          sap.technical_itinerary = ti
          sap.area = area
          sap.planned_at = @activity_tactic.planned_on
          sap.batch_planting = false
          sap.save!
          @logger.info("-----------------Scenario (annual) created for #{@activity.name}")
        elsif @activity.perennial? && ti
          # compute default area with campaign and already affected ap
          area = @activity.productions.where(technical_itinerary_id: ti.id).map{|ap| (ap.support_shape_area.present? ? (ap.support_shape_area.to_f / 10_000) : 0).round(2)}.compact.sum

          # link activity and scenario
          sa = ScenarioActivity.find_or_create_by(scenario: @scenario, activity: @activity)
          # create one plot for all activity
          sap = ScenarioActivity::Plot.find_or_initialize_by(scenario_activity: sa)
          sap.technical_itinerary = ti
          sap.area = area.round(2)
          sap.planned_at = @activity_tactic.planned_on
          sap.batch_planting = false
          sap.save!
          @logger.info("-----------------Scenario (annual) created for #{@activity.name}")
        else
          @logger.error("-----------------No scenario created because no TI exist for #{@activity.name}")
        end
      end

      # itk | (dynamic / static)
      def create_budget_from_itk
        technical_itinerary = @activity_tactic.technical_itinerary if @activity_tactic
        unless technical_itinerary
          @logger.error("No technical_itinerary found")
          return nil
        end
        # find corresponding budget and remove all previous items
        activity_budget = ActivityBudget.find_or_initialize_by(activity_id: @activity.id, campaign_id: @campaign.id)
        activity_budget.currency = Preference[:currency]
        activity_budget.nature = 'compute_from_lexicon'
        activity_budget.technical_itinerary_id = technical_itinerary.id
        activity_budget.items&.where(origin: 'itk')&.destroy_all
        activity_budget.save!
        # find ti from activity and campaing and set new ti

        scenario_activity = ScenarioActivity.find_by(scenario: @scenario, activity: @activity)
        if scenario_activity
          scenario_activity.plots.each do |sap|
            dc = sap.generate_daily_charges
            dc.each do |daily_charge|
              if %w[input output].include?(daily_charge.product_general_type)
                @logger.info("Create budget item for #{daily_charge.inspect}")
                create_budget_item_from_itk(activity_budget, daily_charge)
              end
            end
          end
        else
          @logger.error("No Budget item created because no scenario activity exist for #{@activity.name}")
        end
        activity_budget.reload
        # create fixed direct charges from MasterBudget
        master_budget_items = MasterBudget.of_family(@activity.family)
        if master_budget_items.any?
          master_budget_items.each do |master_budget_item|
            create_budget_fixed_item_from_master_budget(activity_budget, master_budget_item)
          end
        else
          @logger.error("No Budget item created because no direct fixed charges budget activity exist in Lexicon for #{@activity.name}")
        end
      end

      # itk | dynamic
      def create_budget_item_from_itk(activity_budget, daily_charge)
        used_on = daily_charge.reference_date
        # quantity = daily_charge.quantity # in population of variant
        area_in_hectare = (daily_charge.area.to_f > 0.0 ? daily_charge.area : 1.0) # in hectare
        inter_template_prod_param = InterventionTemplate::ProductParameter.find_by(id: daily_charge.intervention_template_product_parameter_id)
        if inter_template_prod_param
          variant = inter_template_prod_param.product_nature_variant
          if variant
            main_product = %i[output].include?(inter_template_prod_param.find_general_product_type) && %i[grain silage milk wine juice fermented_juice fruit].include?(variant.variety.to_sym)
            # get quantity, unit and computation method return {computation_method: ,quantity: ,indicator: , unit: ,unit_amount:}
            qup = find_quantity_unit_price(inter_template_prod_param, variant, area_in_hectare)
            unit = Unit.import_from_lexicon(qup[:unit])
          else
            @logger.error("No Variant found for inter_template_prod_param ID : #{inter_template_prod_param.id}")
          end
        else
          @logger.error("No ITPP found for daily_charge ID : #{daily_charge.id}")
        end

        # create budget_item
        if variant && used_on && inter_template_prod_param && qup.presence
          # create budget item
          activity_budget_item = activity_budget.items.find_or_initialize_by(variant_id: variant.id, used_on: used_on, origin: :itk, nature: :dynamic)
          activity_budget_item.direction = qup[:direction]
          activity_budget_item.unit_id = unit.id if unit
          activity_budget_item.product_parameter_id = inter_template_prod_param.id
          activity_budget_item.variant_indicator = qup[:indicator]
          activity_budget_item.computation_method = qup[:computation_method]
          activity_budget_item.quantity = qup[:quantity] || 1
          activity_budget_item.unit_amount = qup[:unit_amount] || 0.0
          activity_budget_item.main_output = main_product
          activity_budget_item.tax = find_default_tax_on_variant(variant, qup[:direction])
          activity_budget_item.save!
          @logger.info("budget_item_from_itk created for #{variant.name}")
        else
          @logger.error("budget_item_from_itk not created for #{variant.name}")
        end
      end

      def find_quantity_unit_price(inter_template_prod_param, variant, area_in_hectare)
        # for input only
        response = {}
        quantity_in_unit = inter_template_prod_param.global_quantity_in_unit(area_in_hectare)
        @logger.info("Quantity in unit is #{quantity_in_unit.inspect}")

        if %i[input].include?(inter_template_prod_param.find_general_product_type)
          response[:computation_method] = :per_working_unit
          response[:direction] = :expense
          catalog = Catalog.where(usage: %w[cost purchase stock])
        elsif %i[output].include?(inter_template_prod_param.find_general_product_type)
          response[:computation_method] = :per_working_unit
          response[:direction] = :revenue
          catalog = Catalog.where(usage: %w[cost sale])
        end

        if catalog
          response[:quantity] = (quantity_in_unit.value / area_in_hectare).round(2)
          @logger.info("Quantity per hectare is #{response[:quantity]}")
          last_catalog_item = CatalogItem.find_by(variant_id: variant.id, catalog_id: catalog.pluck(:id))
          if last_catalog_item
            @logger.info("last_catalog_item found for #{variant.name} | ID : #{last_catalog_item.id} | amount : #{last_catalog_item.amount} | unit : amount : #{last_catalog_item.unit.reference_name}")
            unit_amount_with_indicator = last_catalog_item.unit_amount_in_target_unit(quantity_in_unit.unit)
            response[:unit_amount] = unit_amount_with_indicator[:unit_amount]
            response[:unit] = unit_amount_with_indicator[:unit]
            response[:indicator] = unit_amount_with_indicator[:indicator]
            @logger.info("last_catalog_item conversion for #{variant.name} | unit_amount : #{response[:unit_amount]} - unit : #{response[:unit]} - indicator : #{response[:indicator]}")
          else
            if variant.type == 'Variants::Articles::PlantMedicineArticle'
              MasterPhytosanitaryPrice.where(reference_article_name: variant.france_maaid).each do |v_price|
                CatalogItem.import_from_lexicon(v_price.reference_name)
              end
            else
              MasterPrice.where(reference_article_name: variant.reference_name).each do |v_price|
                CatalogItem.import_from_lexicon(v_price.reference_name)
              end
            end
            created_catalog_item = CatalogItem.find_by(variant_id: variant.id, catalog_id: catalog.pluck(:id))
            if created_catalog_item
              unit_amount_with_indicator = created_catalog_item.unit_amount_in_target_unit(quantity_in_unit.unit)
              response[:unit_amount] = unit_amount_with_indicator[:unit_amount]
              response[:unit] = unit_amount_with_indicator[:unit]
              response[:indicator] = unit_amount_with_indicator[:indicator]
              @logger.info("price created for #{variant.name} | unit_amount : #{response[:unit_amount]} - unit : #{response[:unit]} - indicator : #{response[:indicator]}")
            else
              @logger.error("No price exist for #{variant.name}")
            end
          end
        end
        response
      end

      # itk | static
      def create_budget_fixed_item_from_master_budget(activity_budget, master_budget_item)
        used_on = master_budget_item.first_used_on(@campaign.harvest_year)
        day_gap = master_budget_item.day_gap
        variant = ProductNatureVariant.import_from_lexicon(master_budget_item.variant)
        unit = Unit.import_from_lexicon(master_budget_item.unit)

        if variant && used_on
          activity_budget_item = activity_budget.items.find_or_initialize_by(variant_id: variant.id, used_on: used_on, origin: :itk, nature: :static)
          activity_budget_item.direction = master_budget_item.direction
          activity_budget_item.unit_id = unit.id if unit
          activity_budget_item.variant_indicator = 'population'
          activity_budget_item.computation_method = master_budget_item.computation_method
          activity_budget_item.quantity = master_budget_item.quantity || 1.0
          activity_budget_item.unit_amount = master_budget_item.unit_pretax_amount || 0.0
          activity_budget_item.frequency = master_budget_item.frequency
          activity_budget_item.repetition = master_budget_item.repetition
          activity_budget_item.tax = find_default_tax_on_variant(variant, master_budget_item.direction)
          activity_budget_item.save!
          @logger.info("budget_item_from_master_budget created for #{variant.name}")
        else
          @logger.error("budget_item_from_master_budget not created for #{variant.name}")
        end
      end

      def find_default_tax_on_variant(variant, direction)
        sale_tax = variant.category.sale_taxes
        purchase_tax = variant.category.purchase_taxes
        # find default tax on variant
        if direction.to_sym == :expense && purchase_tax.any?
          purchase_tax.first
        elsif direction.to_sym == :revenue && sale_tax.any?
          sale_tax.first
        else
          nil
        end
      end

    end
  end
end
