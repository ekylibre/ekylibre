# frozen_string_literal: true

module TechnicalItineraries
  module Itk
    class CreateAuxiliaryBudget
      attr_reader :activity, :campaign

      def initialize(activity:, campaign:)
        @activity = activity
        @campaign = campaign
        @logger ||= Logger.new(File.join(Rails.root, 'log', "itk-#{@campaign.name}-#{Ekylibre::Tenant.current.to_s}.log"))
      end

      # automatic | static
      def create_budget_from_lexicon
        # find corresponding budget and remove all previous items
        activity_budget = ActivityBudget.find_or_create_by!(activity_id: @activity.id, campaign_id: @campaign.id)
        activity_budget.nature = 'compute_from_lexicon'
        activity_budget.items&.where(origin: 'automatic')&.destroy_all
        activity_budget.save!

        master_budget_items = MasterBudget.of_family(@activity.family)
        if master_budget_items.any?
          master_budget_items.each do |master_budget_item|
            create_budget_item_from_master_budget(activity_budget, master_budget_item)
          end
        else
          @logger.error("No Budget item created because no budget activity exist in Lexicon for #{@activity.name}")
        end
      end

      def create_budget_item_from_master_budget(activity_budget, master_budget_item)

        used_on = master_budget_item.first_used_on(@campaign.harvest_year)
        variant = ProductNatureVariant.import_from_lexicon(master_budget_item.variant)
        unit = Unit.import_from_lexicon(master_budget_item.unit)
        if variant && used_on
          activity_budget_item = activity_budget.items.find_or_initialize_by(variant_id: variant.id, used_on: used_on, origin: :automatic, nature: :static)
          activity_budget_item.direction = master_budget_item.direction
          activity_budget_item.unit_id = unit.id if unit
          activity_budget_item.variant_indicator = 'population'
          activity_budget_item.computation_method = master_budget_item.computation_method
          activity_budget_item.quantity = master_budget_item.quantity || 1.0
          activity_budget_item.unit_amount = master_budget_item.unit_pretax_amount || 0.0
          activity_budget_item.frequency = master_budget_item.frequency
          activity_budget_item.repetition = master_budget_item.repetition
          activity_budget_item.save!
          # update used_on
          @logger.info("budget_item_from_master_budget created for #{variant.name}")
        else
          @logger.error("budget_item_from_master_budget not created for #{variant.name}")
        end
      end

    end
  end
end
