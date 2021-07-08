module Backend
  class MasterCropProductionsController < Backend::BaseController
    unroll translation: :fra, primary_key: :reference_name

    def show
      return unless @master_crop_production = MasterCropProduction.find_by(reference_name: params[:reference_name])

      respond_to do |format|
        format.json
      end
    end
  end
end
