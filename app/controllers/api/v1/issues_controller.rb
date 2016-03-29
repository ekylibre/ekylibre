module Api
  module V1
    # Issues API permits to access issues
    class IssuesController < Api::V1::BaseController
      def index
        render json: Issue.order(id: :desc).limit(25), status: :ok
      end

      def create
        issue = Issue.new(permitted_params)
        if issue.save
          render json: { id: issue.id }, status: :created
        else
          render json: issue.errors, status: :unprocessable_entity
        end
      end

      protected

      def permitted_params
        params.permit(:name, :nature, :description, :geolocation, :gravity, :priority, :observed_at, :target_id, :target_type, :state)
      end
    end
  end
end
