module Api
  module V1
    # Interventions Participations API permits to access interventions participations
    class InterventionParticipationsController < Api::V1::BaseController
      def create
        filtered_params = permitted_params
        return render json: { message: 'No working periods given' }, status: :unprocessable_entity if filtered_params.blank? || filtered_params[:working_periods].nil? || filtered_params[:working_periods].empty?
        return render json: { message: 'No current user' }, status: :unprocessable_entity unless current_user && current_user.person

        if current_user && !current_user.worker && current_user.person
          # create a worker which match given user to prevent bad fail
          Worker.create!(
            born_at: Date.today - 25.years,
            person: current_user.person,
            name: current_user.name,
            variant: ProductNatureVariant.import_from_nomenclature(:technician)
          )
          current_user.reload
        end
        if filtered_params[:request_intervention_id]
          intervention = Intervention.find(filtered_params[:request_intervention_id]).initialize_record(state: :in_progress)

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
            procedure_name: Procedo.find(filtered_params[:procedure_name]) ? filtered_params[:procedure_name] : nil
          )
        end
        participation.request_compliant = !filtered_params[:request_compliant].to_i.zero?
        participation.state = filtered_params[:state]
        participation.save!

        filtered_params[:working_periods] ||= []
        filtered_params[:working_periods].each do |wp_params|
          period = participation.working_periods.find_or_initialize_by(
            **wp_params
            .deep_symbolize_keys
          )
          next if period.save
          period.destroy
        end

        if filtered_params[:crumbs].present?
          filtered_params[:crumbs].each do |crumb|
            participation.crumbs.create!(
              nature: crumb['nature'],
              geolocation: crumb['geolocation'],
              read_at: crumb['read_at'],
              accuracy: crumb['accuracy'],
              device_uid: filtered_params[:device_uid],
              user_id: current_user
            )
          end
        end

        render json: { id: participation.id }, status: :created
      end

      private

      def permitted_params
        super.permit(:request_intervention_id, :procedure_name, { working_periods: %i[started_at stopped_at nature] }, :request_compliant, :state, :device_uid, crumbs: %i[read_at accuracy geolocation nature])
      end
    end
  end
end
