module Backend
  class MasterProductionNaturesController < Backend::BaseController
    unroll :human_name_fra

    def show
      return unless @master_production_nature = MasterProductionNature.find(params[:id])

      respond_to do |format|
        format.json
      end
    end
  end
end
