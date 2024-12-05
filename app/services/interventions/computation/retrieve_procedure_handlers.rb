# frozen_string_literal: true

module Interventions
  module Computation
    class RetrieveProcedureHandlers
      def initialize(parameters)
        @procedure = Procedo::Procedure.find(parameters[:procedure_name])
        @parameters = parameters
      end

      # Get correct procedure handlers depending on indicator, unit and name given
      def perform
        retrieve_handlers(@parameters)
        if @parameters[:group_parameters_attributes]
          @parameters[:group_parameters_attributes].each do |group_attrs|
            retrieve_handlers(group_attrs)
          end
        end
        @parameters
      end

      private

        def retrieve_handlers(params)
          %w[inputs_attributes outputs_attributes].each do |type|
            params.fetch(type, []).each do |attrs|
              attrs[:quantity_handler] = retrieve_handler(attrs)
              attrs.delete(:quantity_name)
              attrs.delete(:quantity_indicator)
              attrs.delete(:quantity_unit)
            end
          end
        end

        def retrieve_handler(attrs)
          handlers = @procedure.parameters.find { |p| p.name == attrs[:reference_name].to_sym }.handlers
          return if handlers.empty?

          # Same behaviour as in procedo : if 'name' field is not specified, it takes the value of 'indicator' field
          attrs[:quantity_name] ||= attrs[:quantity_indicator]
          # Filter by name
          handlers.select! { |ih| ih.name == attrs[:quantity_name].to_sym } if attrs[:quantity_name]
          # Filter by unit
          handlers.select! { |ih| ih.unit&.name == attrs[:quantity_unit] } if attrs[:quantity_unit]
          # Filter by indicator
          handlers.select! { |ih| ih.indicator&.name == attrs[:quantity_indicator] } if attrs[:quantity_indicator]
          if handlers.count == 1
            handlers.last.name
          else
            raise "No handler found for: #{attrs.inspect}"
          end
        end
    end
  end
end
