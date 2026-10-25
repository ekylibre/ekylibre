module Api
  module V2
    class ProceduresController < Api::V2::BaseController
      # GET /api/v2/procedures
      # Lists all procedures defined in `config/procedures/*.xml` and registered
      # via Procedo. Supports basic filtering and excludes deprecated/hidden
      # procedures by default.
      #
      # Authentication: required.
      #
      # Query string params:
      # - category           [String, optional] Filter by category name (e.g. "animal_breeding")
      # - procedure_action   [String, optional] Filter by Procedo action name. Note: NOT
      #                      `action` — Rails reserves `params[:action]` for the controller
      #                      action name, which silently filters everything out.
      # - activity_family    [String, optional] Filter by activity family
      # - include_deprecated [String, optional] "true" to include deprecated procedures
      # - include_hidden     [String, optional] "true" to include hidden procedures
      #
      # Responses:
      # - 200 OK  Array of procedures with their parameters tree
      def index
        @procedures = filter_procedures(Procedo.procedures)
        render 'api/v2/procedures/index'
      end

      # GET /api/v2/procedures/:id
      # Returns the full description of a single procedure by name, including
      # all parameters (groups, targets, inputs, outputs, tools, doers) with
      # their cardinality, filter and handlers.
      #
      # Authentication: required.
      #
      # URL params:
      # - id [String, required] Procedure name (e.g. "animal_artificial_insemination")
      #
      # Responses:
      # - 200 OK         Procedure object
      # - 404 Not Found  Procedure does not exist
      def show
        @procedure = Procedo.find(params[:id].to_sym)
        return render json: { errors: ["Procedure not found: #{params[:id]}"] }, status: :not_found unless @procedure

        render 'api/v2/procedures/show'
      end

      private

        def filter_procedures(list)
          if params[:include_deprecated] != 'true'
            list = list.reject(&:deprecated?)
          end
          if params[:include_hidden] != 'true'
            list = list.reject(&:hidden?)
          end
          if params[:category].present?
            list = list.select { |p| p.of_category?(params[:category].to_sym) }
          end
          if params[:procedure_action].present?
            list = list.select { |p| p.has_action?(params[:procedure_action]) }
          end
          if params[:activity_family].present?
            list = list.select { |p| p.of_activity_family?(params[:activity_family].to_sym) }
          end
          list
        end
    end
  end
end
