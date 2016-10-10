module Api
  module V1
    # Interventions API permits to access interventions
    class InterventionParticipationsController < Api::V1::BaseController
      def create
        params = permitted_params[:intervention]
        intervention = Intervention.find_or_create_by!(
          request_intervention_id:  params[:request_intervention_id],
          procedure_name:           params[:procedure_name]
        )
        participations = params[:working_periods].map do |participation_params|
          next if interventions.participations.where('(started_at, stopped_at) OVERLAPS (?, ?)', participation_params[:started_at], participation_params[:stopped_at]).any?
          intervention.participations.find_or_create_by!(**participation_params.merge(product_id: current_user.id))
        end

        intervention.request_compliant &&= params[:request_compliant]
        intervention.state = params[:state]
        intervention.save!

        render json: { participations_ids: participations.compact.map(&:id) }, status: :created
      end

      private

      def permitted_params
        super.require(:intervention).permit(:request_intervention_id, :procedure_name, { working_periods: [:started_at, :stopped_at, :nature] }, :request_compliant, :state)
      end
    end
  end
end