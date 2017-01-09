module Api
  module V1
    # Interventions Participations API permits to access interventions participations
    class InterventionParticipationsController < Api::V1::BaseController
      def create
        params = permitted_params
        return render json: { message: :unprocessable_entity }, status: :unprocessable_entity if params.blank?
        if current_user && !current_user.worker && current_user.person
          # create a worker which match given user to prevent bad fail
          Worker.create!(
            born_at: Date.today - 25.years,
            person: current_user.person,
            name: current_user.name,
            variant: ProductNatureVariant.import_from_nomenclature(:technician)
          )
        end
        if params[:request_intervention_id]
          intervention = Intervention.find(params[:request_intervention_id]).initialize_record(state: :in_progress)

          intervention.creator_id = current_user
          intervention.created_at = Time.zone.now
          intervention.save!
          participation = InterventionParticipation.find_or_initialize_by(
            product: current_user.worker,
            intervention_id: intervention.id
          )
        else
          participation = InterventionParticipation.new(
            product: current_user.worker,
            procedure_name: Procedo.find(params[:procedure_name]) ? params[:procedure_name] : nil
          )
        end
        participation.request_compliant = !params[:request_compliant].to_i.zero?
        participation.state = params[:state]
        participation.save!

        params[:working_periods] ||= []
        params[:working_periods].each do |wp_params|
          period = participation.working_periods.find_or_initialize_by(
            **wp_params
            .deep_symbolize_keys
          )
          next if period.save
          period.destroy
        end

        if params[:crumbs].present?
          params[:crumbs].each do |crumb|
            participation.crumbs.create!(
              nature: crumb['nature'],
              geolocation: crumb['geolocation'],
              read_at: crumb['read_at'],
              accuracy: crumb['accuracy'],
              device_uid: params[:device_uid],
              user_id: current_user
            )
          end
        end

        render json: { id: participation.id }, status: :created
      end

      private

      def permitted_params
        super.permit(:request_intervention_id, :procedure_name, { working_periods: [:started_at, :stopped_at, :nature] }, :request_compliant, :state, :device_uid, crumbs: [:read_at, :accuracy, :geolocation, :nature])
      end
    end
  end
end
