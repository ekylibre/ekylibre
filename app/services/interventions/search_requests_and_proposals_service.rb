# frozen_string_literal: true

module Interventions
  class SearchRequestsAndProposalsService
    attr_reader :product, :last_intervention_record

    def initialize(product: nil)
      @product = product

      @last_intervention_record = find_last_intervention_record
    end

    def perform
      return [] if @last_intervention_record.nil?

      requested_interventions + proposal_interventions
    end

    private

      def find_last_intervention_record
        product_interventions = @product
                                    .interventions

        return nil if product_interventions.empty?

        records_interventions = product_interventions
                                    .select{ |intervention| intervention.nature.to_sym == :record && intervention.state.to_sym != :rejected }

        return nil if records_interventions.empty?

        records_interventions
            .sort_by(&:started_at)
            .reverse
            .first
      end

      def requested_interventions
        interventions = Intervention
                          .joins(:targets)
                          .where(nature: :request, state: %i[in_progress done validated], intervention_parameters: { product_id: @product.id })

        return [] if interventions.empty?

        interventions
          .select{ |intervention| intervention.started_at > @last_intervention_record.started_at }
      end

      def proposal_interventions
        InterventionProposal
          .joins(:activity_production)
          .where(activity_productions: { support_id: @product.id })
          .select{ |intervention_proposal| intervention_proposal.estimated_date > @last_intervention_record.started_at }
      end
  end
end
