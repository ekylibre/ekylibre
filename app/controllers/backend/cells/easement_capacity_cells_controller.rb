module Backend
  module Cells
    class EasementCapacityCellsController < Backend::Cells::BaseController
      def show
        @varieties = BuildingDivision.where(with_easement_capacity: true).pluck(:easement_capacity_variety).compact.sort.uniq
      end
    end
  end
end
