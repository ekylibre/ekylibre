class Pasteque::V5::CompositionsController < Pasteque::V5::BaseController
  manage_restfully only: [:index, :show]
end
