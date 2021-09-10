# frozen_string_literal: true

module Interventions
  class BuildInterventionWithProposalService
    attr_reader :intervention, :intervention_proposal

    def initialize(intervention_proposal)
      @intervention_proposal = intervention_proposal
    end

    def perform
      @intervention = build_intervention

      build_working_periods
      build_product_parameters
      build_group_parameters if @intervention_proposal.procedure.group_parameters.any?

      @intervention
    end

    private

      def build_intervention
        @intervention_proposal.build_intervention(
          {
            nature: :request,
            procedure_name: @intervention_proposal.procedure.name,
            number: @intervention_proposal.number
          }
        )
      end

      def build_working_periods
        started_at = intervention_proposal.estimated_date.to_time + 8.hours

        @intervention
          .working_periods
          .build(
            {
              started_at: started_at,
              stopped_at: started_at + intervention_proposal.estimated_working_time.hours
            }
          )
      end

      def build_product_parameters
        procedure = @intervention_proposal.procedure

        @intervention_proposal.parameters.each do |parameter|
          parameter_reference = proposal_parameter_reference(parameter, procedure)

          next if parameter_reference.nil?

          procedure_parameters = procedure
                                   .parameters
                                   .select { |parameter| parameter.is_a?(::Procedo::Procedure::ProductParameter) && parameter.name == parameter_reference.to_sym }

          build_parameters(parameter, procedure_parameters) if procedure_parameters.any?
          build_parameter(parameter, nil) if procedure_parameters.empty?
        end
      end

      def build_parameters(proposal_parameter, procedure_parameters)
        procedure_parameters.each do |procedure_parameter|
          build_parameter(proposal_parameter, procedure_parameter)
        end
      end

      def build_parameter(proposal_parameter, procedure_parameter)
        procedure_parameter_name = @intervention_proposal.target
        procedure_parameter_name = procedure_parameter.name unless procedure_parameter.nil?

        product_type = proposal_parameter.product_type.to_sym == :parcel ? :targets : proposal_parameter.product_type
        return if (product_type.to_sym == :tool || product_type.to_sym == :doer) &&
                    proposal_parameter.product.nil? && proposal_parameter.variant.nil?

        parcel_product = @intervention_proposal
                       .parameters
                       .of_product_type(:parcel)
                       .first
                       .product

        working_zone = proposal_parameter.product&.shape unless proposal_parameter.product.nil?
        working_zone ||= parcel_product.shape unless parcel_product.nil?

        quantity_population = proposal_parameter.quantity
        quantity_population ||= parcel_product.population unless parcel_product.nil?

        @intervention
          .send(product_type.to_s.pluralize)
          .build(
            {
              product: proposal_parameter.product,
              variant: proposal_parameter.variant,
              quantity_population: quantity_population,
              quantity_value: proposal_parameter.quantity,
              quantity_unit_name: proposal_parameter.unit,
              quantity_handler: proposal_parameter.unit,
              working_zone: working_zone,
              reference_name: procedure_parameter_name
            }
          )
      end

      def proposal_parameter_reference(proposal_parameter, procedure)
        template_product_parameter = proposal_parameter.intervention_template_product_parameter

        unless template_product_parameter.nil?
          return template_product_parameter.procedure['type']
        end

        if proposal_parameter.product_type.to_sym == :output
          parameter_reference = procedure
                                  .parameters
                                  .select { |parameter| parameter.is_a?(::Procedo::Procedure::ProductParameter) && parameter.output?}
                                  .first

          return parameter_reference.name unless parameter_reference.nil?
        end

        if proposal_parameter.product_type.to_sym == :parcel
          parameter_reference = procedure
                                  .product_parameters
                                  .select { |parameter| parameter.name == :cultivation || parameter.name == :plant || parameter.name == :land_parcel }
                                  .first

          return parameter_reference.name unless parameter_reference.nil?
        end

        return :parcel
      end

      def build_group_parameters
        @intervention
          .group_parameters
          .build(
            {
              targets: @intervention.targets,
              outputs: @intervention.outputs,
              product_id: @intervention_proposal.parameters.of_product_type(:parcel).last&.product&.id,
              reference_name: @intervention_proposal.procedure.group_parameters.first.name
            }
          )
      end
  end
end
