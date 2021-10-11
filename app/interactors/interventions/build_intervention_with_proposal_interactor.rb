# frozen_string_literal: true

module Interventions
  class BuildInterventionWithProposalInteractor
    def self.call(params)
      interactor = new(params)
      interactor.run
      interactor
    end

    attr_reader :intervention_proposal, :intervention, :error

    def initialize(params)
      @intervention_proposal = InterventionProposal.find(params[:proposal_id])
    end

    def run
      begin
        @intervention = Interventions::BuildInterventionWithProposalService
                          .new(@intervention_proposal)
                          .perform
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

      def fail!(error)
        @error = error
      end
  end
end
