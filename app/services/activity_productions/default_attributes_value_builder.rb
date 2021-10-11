# frozen_string_literal: true

module ActivityProductions
  # Build activity production default values
  class DefaultAttributesValueBuilder
    def initialize(activity, campaign)
      @activity = activity
      @campaign = campaign
    end

    def self.build(activity, campaign)
      new(activity, campaign).build
    end

    # @return [Hash] attributes
    def build
      {
        usage: usage,
        started_on: started_on,
        stopped_on: stopped_on,
        starting_year: starting_year,
        reference_name: activity.reference_name
      }
    end

    private

      attr_reader :activity, :campaign

      def usage
        activity.usage
      end

      def started_on
        if activity.production_started_on.present? && activity.production_started_on_year.present?
          activity.production_started_on.change(year: campaign.harvest_year + activity.production_started_on_year)
        else
          Date.today.change(year: campaign.harvest_year)
        end
      end

      def stopped_on
        if activity.production_stopped_on.present? && activity.life_duration.present?
          activity.production_stopped_on.change(year: started_on.year + activity.life_duration )
        elsif activity.production_stopped_on.present? && activity.production_stopped_on_year.present?
          activity.production_stopped_on.change(year: campaign.harvest_year + activity.production_stopped_on_year)
        elsif activity.life_duration.present?
          (Date.today - 1.day).change(year: campaign.harvest_year + activity.life_duration)
        else
          (Date.today - 1.day).change(year: campaign.harvest_year + 1)
        end
      end

      def starting_year
        return if activity.annual?

        if activity.start_state_of_production_year.present?
          started_on.year + activity.start_state_of_production_year
        end
      end
  end
end
