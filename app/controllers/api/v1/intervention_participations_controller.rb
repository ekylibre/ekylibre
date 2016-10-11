module Api
  module V1
    # Interventions Participations API permits to access interventions participations
    class InterventionParticipationsController < Api::V1::BaseController
      def create
        params = permitted_params

        intervention = Intervention.find_or_create_by!(
          request_intervention_id:  params[:request_intervention_id],
          procedure_name:           params[:procedure_name]
        )

        participation = intervention.participations.find_or_initialize_by(
          intervention_id: intervention.id,
          product_id: current_user.id
        )

        participation.request_compliant = params[:request_compliant]
        participation.state = params[:state]
        participation.save!

        params[:working_periods].map do |wp_params|
          period = InterventionWorkingPeriod.find_or_initialize_by(
            **wp_params
            .merge(intervention_participation_id: participation.id)
            .deep_symbolize_keys
          )
          next if participation.working_periods.where('(started_at, stopped_at) OVERLAPS (?, ?)', period.started_at, period.stopped_at).any?
          period.save!
        end

        intervention.state = intervention.participations.pluck(:state).any? { |s| s == :in_progress }
        intervention.save!

        render json: { id: participation.id }, status: :created
      end

      private

      def permitted_params
        super.permit(:request_intervention_id, :procedure_name, { working_periods: [:started_at, :stopped_at, :nature] }, :request_compliant, :state)
      end
    end
  end
end
