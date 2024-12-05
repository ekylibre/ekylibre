module Api
  module V2
    class FarmProfilesController < Api::V2::BaseController
      def show
        if params[:harvest_year].present?
          @farm_profile = FarmProfiles::GeneralInformations.new(params[:harvest_year].to_i)
          response = {
                        general_informations: @farm_profile.farm_informations,
                        weather_informations: @farm_profile.watering_and_climatic_data,
                        biodiversity_informations: @farm_profile.biodiversity_informations,
                        crop_rotations_n: @farm_profile.crop_rotations(:current),
                        crop_rotations_n_1: @farm_profile.crop_rotations(:preceding),
                        crop_rotations_n_2: @farm_profile.crop_rotations(:antepreceding)
          }.to_json
          render status: :ok, json: response
        else
          render status: :bad_request, json: { errors: :missing_harvest_year_parameter.tl }
        end
      end
    end
  end
end
