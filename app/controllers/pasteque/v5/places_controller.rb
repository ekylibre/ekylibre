module Pasteque
  module V5
    class PlacesController < Pasteque::V5::BaseController
      def index
        @records = []
      end

      def show
        render json: { status: :rej, content: 'No place here' }
      end
    end
  end
end
