module Pasteque
  module V5
    class AttributesController < Pasteque::V5::BaseController
      manage_restfully only: [:index]
    end
  end
end
