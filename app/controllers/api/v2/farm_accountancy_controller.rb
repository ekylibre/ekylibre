module Api
  module V2
    class FarmAccountancyController < Api::V2::BaseController
      def show
        if params[:harvest_year].present?
          @farm_profile = FarmProfiles::AccountancyInformations.new(params[:harvest_year].to_i)
          response = {
                        global_ratio: @farm_profile.global_ratio_informations,
                        accountancy: @farm_profile.accountancy_informations,
                        economic: @farm_profile.economic_informations

          }.to_json
          render status: :ok, json: response
        else
          render status: :bad_request, json: { errors: :missing_harvest_year_parameter.tl }
        end
      end
    end
  end
end
