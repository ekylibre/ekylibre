# frozen_string_literal: true

module Interventions
  module Phytosanitary
    class PfiComputation
      attr_reader :campaign, :intervention, :activities

      def initialize(campaign:, intervention: nil, activities: nil)
        @campaign = campaign
        @intervention = intervention
        @activities = activities
      end

      # return a Hash {code: ,body: }
      def create_pfi_report
        return { status: false, body: :no_activities_found } if @activities.nil?

        pfi_call = Interventions::Phytosanitary::PfiClientApi.new(campaign: @campaign, activities: @activities)
        response = pfi_call.compute_pfi_report
      end

      def create_or_update_pfi
        return nil if @intervention.nil?

        # get first activity for the moment
        # TODO return nil if activity is not uniq
        activity = @intervention.activities.first
        area_cost_coefficient = (@intervention.area_cost_coefficient * 100).round(2)
        global_area_ratio = area_cost_coefficient <= 100 ? area_cost_coefficient : 100
        @intervention.inputs.each do |input|
          # compute pfi for each input in intervention for all target
          # call API with parameters
          pfi_call = Interventions::Phytosanitary::PfiClientApi.new(campaign: @campaign, activity: activity, intervention_parameter_input: input, area_ratio: global_area_ratio, notify_user: true)
          response = pfi_call.compute_pfi
          if response
            # update pfi_intervention_paramter with API response
            pfi = PfiInterventionParameter.find_or_initialize_by(campaign_id: @campaign.id, input_id: input.id, nature: :intervention)
            pfi.response = response
            pfi.pfi_value = response[:iftTraitement][:ift].to_d
            pfi.segment_code = response[:iftTraitement][:segment][:idMetier].to_s
            pfi.signature = response[:signature]
            pfi.save!
          end

          # compute pfi for each target relative to current input in intervention
          @intervention.targets.each do |target|
            # compute ratio from working_zone and surface area of land_parcel or plant in square meter
            target_working_area = target.working_area
            crop_area = target&.product&.get(:net_surface_area)
            target_area_ratio = if target_working_area && crop_area
                                  ratio = ((target_working_area.convert(:square_meter).to_f / crop_area.convert(:square_meter).to_f).round(2) * 100)
                                  ratio <= 100 ? ratio : 100
                                end

            pfi_call = Interventions::Phytosanitary::PfiClientApi.new(campaign: @campaign, activity: activity, intervention_parameter_input: input, area_ratio: target_area_ratio)
            response = pfi_call.compute_pfi
            if response
              # update pfi_intervention_parameter with API response
              pfi = PfiInterventionParameter.find_or_initialize_by(campaign_id: @campaign.id, input_id: input.id, target_id: target.id, nature: :crop)
              pfi.response = response
              pfi.pfi_value = response[:iftTraitement][:ift].to_d
              pfi.segment_code = response[:iftTraitement][:segment][:idMetier].to_s
              pfi.signature = response[:signature]
              pfi.save!
            end
          end
        end
      end

    end
  end
end
