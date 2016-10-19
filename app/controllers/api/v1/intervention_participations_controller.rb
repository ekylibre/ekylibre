module Api
  module V1
    # Interventions Participations API permits to access interventions participations
    class InterventionParticipationsController < Api::V1::BaseController
      def create
        params = permitted_params
        return render json: :unprocessable_entity if params.blank?

        intervention = Intervention.find(params[:request_intervention_id]).initialize_record
        intervention.save!

        participation = intervention.participations.find_or_initialize_by(
          product_id: current_user.worker.id
        )

        participation.request_compliant = !params[:request_compliant].to_i.zero?
        participation.state = params[:state]
        participation.save!

        params[:working_periods].each do |wp_params|
          period = participation.working_periods.find_or_initialize_by(
            **wp_params
            .deep_symbolize_keys
          )
          next if period.save
          period.destroy
        end

        render json: { id: participation.id }, status: :created
      end

      private

      def permitted_params
        super.permit(:request_intervention_id, :procedure_name, { working_periods: [:started_at, :stopped_at, :nature] }, :request_compliant, :state)
      end
    end
  end
end
