module Pasteque
  module V5
    class VersionController < Pasteque::V5::BaseController
      skip_before_action :authenticate_user!

      def index
        render json: { status: 'ok', content: { version: '5', level: 5 } }
      end
    end
  end
end
