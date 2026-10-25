module Api
  module V2
    # Interventions API permits to access interventions
    class InterventionsController < Api::V2::BaseController
      READING_PARAMS = %i[tools targets].freeze

      # GET /api/v2/interventions
      # Lists interventions assigned to a worker, optionally filtered by nature
      # or whether they have child interventions.
      #
      # Authentication: required.
      #
      # Query string params:
      # - contact_email      [String, optional] Filter by entity (contact) email
      # - user_email         [String, optional] Filter by user email
      # - with_interventions [String, optional] "true" / "false" — filter request
      #                                          interventions that have / have not
      #                                          a recorded child intervention
      # - nature             [String, optional] e.g. "request", "record"
      # - provider_id        [String, optional] Filter by provider identifier
      #                                          (provider->>'id'), e.g. the
      #                                          client-supplied UUID
      #
      # Responses:
      # - 200 OK                       Array of interventions
      # - 412 Precondition Required    Worker not associated with the email
      # - 422 Unprocessable Entity     Invalid filter or unknown email
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

        if params[:provider_id]
          @interventions = @interventions.of_provider_id(params[:provider_id])
        end

        @interventions = @interventions.where.not(state: :rejected).order(:id)
      end

      # POST /api/v2/interventions
      # Creates a new recorded intervention with its full graph of nested
      # resources (working periods, inputs, outputs, tools, targets, doers,
      # group_parameters, and readings). Defaults: nature = "record",
      # state = "done", working periods auto-calculated.
      #
      # Authentication: required.
      #
      # Request body params:
      # - id                          [Integer, optional]
      # - procedure_name              [String, required]
      # - description                 [String, optional]
      # - actions                     [Array<String>]
      # - working_periods_attributes  [Array] { id, started_at, stopped_at, _destroy }
      # - inputs_attributes           [Array] { id, product_id, quantity_value,
      #                                        quantity_handler, reference_name,
      #                                        quantity_population, usage_id, _destroy }
      # - outputs_attributes          [Array] { id, variant_id, quantity_value,
      #                                        quantity_handler, reference_name,
      #                                        quantity_population, _destroy }
      # - tools_attributes            [Array] { id, product_id, reference_name,
      #                                        _destroy, readings_attributes[] }
      # - targets_attributes          [Array] { id, product_id, reference_name,
      #                                        _destroy, readings_attributes[] }
      # - doers_attributes            [Array] { id, product_id, reference_name, _destroy }
      # - group_parameters_attributes [Array] { id, reference_name, _destroy,
      #                                        inputs_attributes[], outputs_attributes[],
      #                                        targets_attributes[], tools_attributes[],
      #                                        doers_attributes[] }
      # - provider                    [Object, required]
      #     - vendor [String, required]
      #     - name   [String, required]
      #     - id     [String, optional]
      #     - data   [Object, optional]
      #
      # readings_attributes items: { boolean_value, indicator_name,
      #   measure_value_value, measure_value_unit, choice_value, decimal_value,
      #   string_value }
      #
      # Idempotence: when `provider.id` is set and an intervention already
      # exists for the same (vendor, name, id) triple, the existing one is
      # returned (200 OK) instead of creating a duplicate.
      #
      # Responses:
      # - 201 Created     { "id": <intervention_id> } (new intervention)
      # - 200 OK          { "id": <intervention_id> } (existing, deduplicated)
      # - 400 Bad Request { "errors": [<message>] }
      def create
        params_to_build = create_params

        # Idempotence: when the client supplies a stable provider id (e.g. a
        # UUIDv4 from zero-mobile), an identical retried POST must not create a
        # duplicate. Return the already-recorded intervention instead.
        if (existing = existing_intervention_for_provider(params_to_build[:provider]))
          render json: { id: existing.id }, status: :ok
          return
        end

        interactor = Interventions::BuildInterventionInteractor.new(params_to_build, intervention_options)

        if interactor.run
          intervention = interactor.intervention
          render json: { id: intervention.id }, status: :created
        else
          render json: { errors: [interactor.error.try(:message)] }, status: :bad_request
        end
      end

      # PUT/PATCH /api/v2/interventions/:id
      # Updates an existing intervention. Accepts the same nested attributes as
      # `create`. Children can be removed via `_destroy: true`.
      #
      # Authentication: required.
      #
      # URL params:
      # - id [Integer, required] Intervention id
      #
      # Request body params: same as POST /api/v2/interventions but without
      # the `provider` requirement.
      #
      # Responses:
      # - 200 OK          { "id": <intervention_id> }
      # - 400 Bad Request { "errors": <message> }
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
          # `super` (base controller) extracts and cleans the `provider` block
          # (vendor/name/id + arbitrary `data`). `permit` would drop it since
          # `common_params_to_permit` does not list it, so merge it back to keep
          # the provider persisted on the intervention.
          base = super
          base.permit(common_params_to_permit).merge(provider: base[:provider])
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

        # Looks up an existing intervention matching the (vendor, name, id)
        # provider triple. Only deduplicates when a provider id is supplied —
        # without it there is no stable client identifier to reconcile on.
        #
        # @return [Intervention, nil]
        def existing_intervention_for_provider(provider)
          return if provider.blank? || provider[:id].blank?

          Intervention
            .of_provider(provider[:vendor], provider[:name], provider[:id])
            .where.not(state: :rejected)
            .order(:id)
            .first
        end
    end
  end
end
