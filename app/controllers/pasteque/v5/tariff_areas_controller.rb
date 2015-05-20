class Pasteque::V5::TariffAreasController < Pasteque::V5::BaseController
  manage_restfully only: [:index], model: :catalog, scope: :for_sale
end
