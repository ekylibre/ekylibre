module Api
  module V1
    # Interventions Participations API permits to access interventions participations
    class InterventionParticipationsController < Api::V1::BaseController
      def create
        filtered_params = permitted_params
        payload_errors = params_errors(filtered_params)
        return error_message(payload_errors.join(', ')) if payload_errors.any?

        if current_user.worker.nil?
          # create a worker which match given user to prevent bad fail
          Worker.create!(
            born_at: Date.today - 25.years,
            person: current_user.person,
            name: current_user.name,
            variant: ProductNatureVariant.import_from_nomenclature(:technician)
          )
          current_user.reload
        end

        intervention = Intervention.find_by(id: filtered_params[:intervention_id])
        if intervention
          if intervention.request?
            new_intervention = intervention.initialize_record(state: :in_progress)
            new_intervention.creator_id = current_user
            new_intervention.created_at = Time.zone.now
            new_intervention.description = filtered_params[:description] if filtered_params[:description]
            new_intervention.provider = filtered_params[:provider] if filtered_params[:provider]
            new_intervention.save!
            intervention = new_intervention
            # equipments parameters is expected only to create hour_counter reading associated with the tools of the intervention
            if (equipments = filtered_params[:equipments])
              equipments.each do |equipment|
                product_id = equipment[:product_id]
                tool = intervention.tools.find_by(product_id: product_id)
                return error_message("There is no intervention tool associated with product id #{product_id}") if tool.nil?
                hour_value = equipment[:hour_counter]
                reading = tool.readings.find_or_initialize_by(indicator_name: :hour_counter)
                reading.update!(measure_value_unit: :hour, measure_value_value: hour_value)
              end
            end
          end

          participation = InterventionParticipation.find_or_initialize_by(
            product: current_user.worker,
            intervention_id: intervention.id
          )
          # This case is not relevant anymore for larrere API as crumbs are not used aymore but still usefull for Eky API(waiting for the crumbs to be reviewed and maybe removed in the future)
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
          period = participation.working_periods.find_or_initialize_by(**wp_params.to_h.deep_symbolize_keys)
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
          permitted = super.permit(
            :description,
            :device_uid,
            :intervention_id,
            :procedure_name,
            :request_compliant,
            :state,
            crumbs: %i[read_at accuracy geolocation nature],
            equipments: %i[product_id hour_counter],
            working_periods: %i[started_at stopped_at nature],
          )
          add_provider_params(permitted)
        end

        def params_errors(filtered_params)
          errors = []
          errors << 'No state given' if filtered_params[:state].nil?
          errors << 'No working periods given' if filtered_params.blank? || filtered_params[:working_periods].nil? || filtered_params[:working_periods].empty?
          errors << 'No current user' unless current_user && current_user.person
          errors << "Can't assign hour counter to equipment as the intervention state is not 'done'" if filtered_params[:state] != 'done' && filtered_params[:equipments]
          errors << "Need 'product_id' and 'hour_counter' fields on 'equipments' hash" if filtered_params[:equipments]&.any? { |eq| eq.exclude?(:hour_counter) || eq.exclude?(:product_id) }
          errors
        end
    end
  end
end
