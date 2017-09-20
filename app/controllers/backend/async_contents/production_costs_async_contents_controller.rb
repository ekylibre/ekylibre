module Backend
  module AsyncContents
    class ProductionCostsAsyncContentsController < Backend::AsyncContents::BaseController
      def show
        @activity_production = ActivityProduction.find(params[:id])
      end
    end
  end
end
