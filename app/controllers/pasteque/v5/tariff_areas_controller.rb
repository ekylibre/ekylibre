module Pasteque
  module V5
    class TariffAreasController < Pasteque::V5::BaseController
      manage_restfully only: [:index], model: :catalog, scope: :for_sale
    end
  end
end
