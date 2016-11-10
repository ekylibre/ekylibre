module Api
  module V1
    # Interventions Targets API permits to access data from intervention targets
    class InterventionTargetsController < Api::V1::BaseController
      def show
        @target = InterventionTarget.find_by(id: params[:id])
        if @target
          render json: JSON(@target.to_json).merge('working_zone' => (@target.working_zone.blank? ? @target.working_zone : Charta::Geometry.new(@target.working_zone).to_json)).to_json
        else
          render json: { message: 'Not found' }, status: :not_found
        end
      end
    end
  end
end
