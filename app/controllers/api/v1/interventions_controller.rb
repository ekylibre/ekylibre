module Api
  module V1
    # Interventions API permits to access interventions
    class InterventionsController < Api::V1::BaseController
      READING_PARAMS = %i[tools targets].freeze
      def index
        nature = params[:nature] || 'record'
        @interventions = Intervention
        unless %w[record request].include? nature
          head :unprocessable_entity
          return
        end

        if params[:contact_email]
          entity = Entity.with_email(params[:contact_email])
          unless entity
            head :unprocessable_entity
            return
          end
          @interventions = @interventions.with_doers(entity.worker)
        elsif params[:user_email]
          user = User.find_by(email: params[:user_email])
          unless user
            head :unprocessable_entity
            return
          end
          @interventions = @interventions.with_doers(user.worker)
        end

        return render json: { message: :no_worker_associated_with_user_account.tn }, status: :precondition_required if user && user.worker.nil?

        if nature == 'request'
          @interventions = @interventions.joins(<<-SQL).where(<<-CONDITIONS, user.worker.id).group('interventions.id')
            LEFT JOIN interventions record_interventions_interventions ON record_interventions_interventions.request_intervention_id = interventions.id
            LEFT JOIN intervention_participations ON record_interventions_interventions.id = intervention_participations.intervention_id
            LEFT JOIN products AS workers_or_tools_included ON intervention_participations.product_id = workers_or_tools_included.id AND workers_or_tools_included.type = 'Worker' 
          SQL

            (record_interventions_interventions.state IS NULL
            OR record_interventions_interventions.state = 'in_progress')
            AND (workers_or_tools_included.id IS NULL
            OR (workers_or_tools_included.id = ? AND intervention_participations.state = 'in_progress'))
         CONDITIONS

          if params[:with_interventions]
            if params[:with_interventions] == 'true'
              @interventions = @interventions.where(id: Intervention.select(:request_intervention_id))
            elsif params[:with_interventions] == 'false'
              @interventions = @interventions.where.not(id: Intervention.select(:request_intervention_id))
            else
              head :unprocessable_entity
              return
            end
          end
        end
        @interventions = @interventions.where(nature: nature).where.not(state: :rejected).order(:id)
      end

      def create
        filtered_params = permitted_params
        return error_message('Provider params not provided') unless validate_provider(filtered_params)

        options = {
          auto_calculate_working_periods: true,
          nature: :record,
          state: :done
        }

        interactor = Interventions::BuildInterventionInteractor.new(filtered_params, options)

        if interactor.run
          intervention = interactor.intervention
          render json: { id: intervention.id }, status: :created
        else
          render json: { errors: interactor.error }, status: :bad_request
        end
      end

      protected

        def permitted_params
          permitted = super.permit(
            :procedure_name,
            :description,
            :actions,
            working_periods_attributes: %i[started_at stopped_at],
            inputs_attributes: %i[product_id quantity_value quantity_handler reference_name quantity_population usage_id],
            outputs_attributes: %i[variant_id quantity_value quantity_handler reference_name quantity_population],
            tools_attributes: [:product_id, :reference_name, readings_attributes: %i[indicator_name measure_value_value measure_value_unit]],
            targets_attributes: %i[product_id reference_name],
            doers_attributes: %i[product_id reference_name],
            group_parameters_attributes: [
              :reference_name,
              inputs_attributes: %i[product_id quantity_value quantity_handler reference_name quantity_population],
              outputs_attributes: %i[variant_id quantity_value quantity_handler reference_name quantity_population batch_number variety],
              targets_attributes: [:product_id, :reference_name, readings_attributes: %i[indicator_name measure_value_value measure_value_unit]],
              tools_attributes: %i[product_id reference_name],
              doers_attributes: %i[product_id reference_name]
            ]
          )
          add_provider_params(permitted)
        end
    end
  end
end
