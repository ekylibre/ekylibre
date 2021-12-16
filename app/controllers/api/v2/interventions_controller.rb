module Api
  module V2
    # Interventions API permits to access interventions
    class InterventionsController < Api::V2::BaseController
      READING_PARAMS = %i[tools targets].freeze

      def index
        @interventions = Intervention

        if params[:contact_email]
          user = Entity.with_email(params[:contact_email]).take

          return render json: { errors: [:no_entity_with_email.tn(email: params[:contact_email])] }, status: :unprocessable_entity if user.nil?

          return render json: { errors: [:no_worker_associated_with_entity_account.tn] }, status: :precondition_required if user.worker.nil?

          @interventions = @interventions.with_doers(user.worker)
        end

        if params[:user_email]
          user = User.find_by(email: params[:user_email])
          return render json: { errors: [:no_user_with_email.tn(email: params[:user_email])] }, status: :unprocessable_entity if user.nil?

          return render json: { errors: [:no_worker_associated_with_user_account.tn] }, status: :precondition_required if user && user.worker.nil?

          @interventions = @interventions.with_doers(user.worker)
        end

        worker_id = user.present? ? user.worker.id : nil
        @interventions = @interventions.joins(<<-SQL).where(<<-CONDITIONS, worker_id).group('interventions.id')
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

        if params[:nature]
          @interventions = @interventions.where(nature: params[:nature])
        end

        @interventions = @interventions.where.not(state: :rejected).order(:id)
      end

      def create
        interactor = Interventions::BuildInterventionInteractor.new(create_params, intervention_options)

        if interactor.run
          intervention = interactor.intervention
          render json: { id: intervention.id }, status: :created
        else
          render json: { errors: [interactor.error.try(:message)] }, status: :bad_request
        end
      end

      def update
        interactor = Interventions::BuildInterventionInteractor.new(update_params, intervention_options)

        if interactor.run
          intervention = interactor.intervention
          render json: { id: intervention.id }, status: :ok
        else
          render json: { errors: interactor.error.try(:message) }, status: :bad_request
        end
      end

      protected

        def create_params
          super.permit(common_params_to_permit)
        end

        def update_params
          permitted_params.permit(common_params_to_permit)
        end

        def intervention_options
          {
            auto_calculate_working_periods: true,
            nature: :record,
            state: :done
          }
        end

        def common_params_to_permit
          [
            :id,
            :procedure_name,
            :description,
            actions: [],
            working_periods_attributes: %i[id started_at stopped_at _destroy],
            inputs_attributes: %i[id product_id quantity_value quantity_handler reference_name quantity_population usage_id _destroy],
            outputs_attributes: %i[id variant_id quantity_value quantity_handler reference_name quantity_population _destroy],
            tools_attributes: [:id, :product_id, :reference_name, :_destroy, readings_attributes: readings_attributes],
            targets_attributes: [:id, :product_id, :reference_name, :_destroy, readings_attributes: readings_attributes],
            doers_attributes: %i[id product_id reference_name _destroy],
            group_parameters_attributes: [
              :id,
              :reference_name,
              :_destroy,
              inputs_attributes: %i[id product_id quantity_value quantity_handler reference_name quantity_population _destroy],
              outputs_attributes: [:id, :variant_id, :quantity_value, :quantity_handler, :reference_name, :quantity_population, :batch_number, :specie_variety_name, :_destroy, :new_name, :identification_number, readings_attributes: readings_attributes],
              targets_attributes: [:id, :product_id, :reference_name, :_destroy, readings_attributes: readings_attributes],
              tools_attributes: %i[id product_id reference_name _destroy],
              doers_attributes: %i[id product_id reference_name _destroy]
            ]
          ]
        end

        def readings_attributes
          %i[boolean_value indicator_name measure_value_value measure_value_unit choice_value decimal_value string_value]
        end
    end
  end
end
