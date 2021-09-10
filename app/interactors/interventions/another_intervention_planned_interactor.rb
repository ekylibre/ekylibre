# frozen_string_literal: true

module Interventions
  class AnotherInterventionPlannedInteractor
    def self.call(params)
      interactor = new(params)
      interactor.run
      interactor
    end

    attr_reader :product, :procedure_name, :product_type, :error

    def initialize(params)
      @product = Product.find(params[:id])
      @procedure_name = params[:procedure_name]

      return if @product.nil?

      init_product_type(params)
    end

    def run
      return if @product.nil?

      begin
        interventions = Interventions::SearchRequestsAndProposalsService
                          .new(product: @product)
                          .perform

        return if interventions.empty?

        intervention_to_compare = most_recent_intervention(interventions)

        if different_procedure_name?(intervention_to_compare)
          fail!(I18n.t('errors.messages.intervention_already_planned', product_type: @product_type.tl.lower, intervention_name: intervention_to_compare.name))
        end
      rescue StandardError => exception
        fail!(exception.message)
      end
    end

    def success?
      @error.nil?
    end

    def fail?
      !@error.nil?
    end

    private

      def init_product_type(params)
        @product_type = params[:product_type]
        @product_type ||= @product.type.snakecase

        @product_type = @product_type.to_sym

        @product_type = :land_parcel_name if @product_type == :land_parcel
      end

      def fail!(error)
        @error = error
      end

      def most_recent_intervention(interventions)
        sorted_interventions = interventions
                                 .sort_by do |intervention|
                                   intervention.try(:started_at) || intervention.try(:estimated_date)
                                 end

        sorted_interventions
          .first
      end

      def different_procedure_name?(intervention_to_compare)
        if intervention_to_compare.is_a?(Intervention)
          procedure_name_to_compare = intervention_to_compare
                                        .procedure
                                        .name
        end

        if intervention_to_compare.is_a?(InterventionProposal)
          procedure_name_to_compare = intervention_to_compare
                                        .technical_itinerary_intervention_template
                                        .intervention_template
                                        .procedure_name
        end

        @procedure_name.to_sym != procedure_name_to_compare.to_sym
      end
  end
end
