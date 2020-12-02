module Backend
  module Cells
    class WorkingSetsStocksCellsController < Backend::Cells::BaseController
      def show
        @working_set = params[:working_set] || :matters
        @working_set = @working_set.to_sym
        @indicator = Onoma::Indicator[params[:indicator] || :net_mass]
        @unit = (params[:unit] ? Onoma::Unit[params[:unit]] : @indicator.unit)
      end
    end
  end
end
