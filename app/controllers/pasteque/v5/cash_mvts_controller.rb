module Pasteque
  module V5
    class CashMvtsController < Pasteque::V5::BaseController
      def move
        render json: { status: :rej, content: ['Not supported'] }
      end
    end
  end
end
