module Backend
  class ProductionUsagesController < Backend::BaseController
    def show
      @production_usage = Onoma::ProductionUsage.find(params[:id])
    end
  end
end
