module Pasteque
  module V5
    class StocksController < Pasteque::V5::BaseController
      manage_restfully only: [:index], model: :product, search_filters: { locationId: :default_storage_id }
    end
  end
end
