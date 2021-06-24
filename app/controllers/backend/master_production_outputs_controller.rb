module Backend
  class MasterProductionOutputsController < Backend::BaseController
    respond_to :json

    def index
      @resources = if !search_params.empty?
                     MasterProductionOutput.where(search_params)
                   else
                     MasterProductionOutput.all
                   end
    end

    private def search_params
      params.permit(:main, :production_nature_id)
    end
  end
end
