module Backend
  module Cells
    class MesParcellesSynchronisationCellsController < Backend::Cells::BaseController
      def show
        @campaign = Campaign.current.last
        @integration = Integration.find_by(nature: "mes_parcelles")
      end
    end
  end
end
