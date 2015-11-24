module Pasteque
  module V5
    class CompositionsController < Pasteque::V5::BaseController
      def index
        render json: { status: 'ok', content: [] }
      end
    end
  end
end
