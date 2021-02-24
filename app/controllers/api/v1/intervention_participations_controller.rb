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
            new_intervention = intervention.initialize_record
            new_intervention.creator_id = current_user
            new_intervention.created_at = Time.zone.now
            new_intervention.description = filtered_params[:description] if filtered_params[:description]
            new_intervention.provider = filtered_params[:provider]
            new_intervention.request_compliant = !filtered_params[:request_compliant].to_i.zero?
            new_intervention.state = filtered_params[:state]
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

          if filtered_params[:working_periods].present?
            participation = InterventionParticipation.find_or_initialize_by(
              product: current_user.worker,
              intervention_id: intervention.id
            )
          end
        end

        if participation
          participation.request_compliant = !filtered_params[:request_compliant].to_i.zero?
          participation.state = filtered_params[:state]
          participation.save!

          filtered_params[:working_periods] ||= []
          filtered_params[:working_periods].each do |wp_params|
            period = participation.working_periods.find_or_initialize_by(**wp_params.to_h.deep_symbolize_keys)
            next if period.save

            period.destroy
          end

          if intervention
            working_periods = intervention.participations
                                          .flat_map(&:working_periods)
                                          .map { |wp| wp.slice(:started_at, :stopped_at) }
                                          .sort_by { |wp| wp[:started_at] }

            if working_periods.any?
              # Group consecutive periods (current period stopped_at equals next period started_at) before creating InterventionWorkingPeriod for each group
              dates_groups = []
              following_dates = []

              working_periods.each_with_index do |wp_params, index|
                previous_wp_params = working_periods[index - 1]
                if index != 0 && (wp_params[:started_at] > previous_wp_params[:stopped_at])
                  dates_groups << following_dates
                  following_dates = []
                end
                following_dates << wp_params
              end
              dates_groups << following_dates

              # Use a transaction to ensure there is always a working_period associated with the intervention in case there is a problem during the working_periods creation with dates_groups
              ActiveRecord::Base.transaction do
                intervention.working_periods.delete_all
                dates_groups.each do |group|
                  started_at = group.map { |g| g[:started_at] }.min
                  stopped_at = group.map { |g| g[:stopped_at] }.max
                  InterventionWorkingPeriod.create!(intervention: intervention, started_at: started_at, stopped_at: stopped_at)
                end
                intervention.reload.save!
              end
            end
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
        end

        json = {}
        json[:id] = participation.id if participation
        render json: json, status: :created
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
          errors << 'No current user' unless current_user && current_user.person
          errors << "Can't assign hour counter to equipment as the intervention state is not 'done'" if filtered_params[:state] != 'done' && filtered_params[:equipments]
          errors << "Need 'product_id' and 'hour_counter' fields on 'equipments' hash" if filtered_params[:equipments]&.any? { |eq| !eq.include?(:hour_counter) || !eq.include?(:product_id) }
          errors
        end
    end
  end
end
