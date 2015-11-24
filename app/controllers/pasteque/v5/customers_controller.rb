module Pasteque
  module V5
    class CustomersController < Pasteque::V5::BaseController
      manage_restfully only: [:show], model: :entity, scope: :clients, update_filters: { amount: :amount }

      def index
        @records = model.all
      end

      def top
        params[:limit] ||= 10
        render json: { status: :ok, content: Entity.best_clients(params[:limit].to_i).map(&:id) }
      end
    end
  end
end
