# frozen_string_literal: true

module TechnicalItineraries
  class DailyChargesCreationInteractor
    def self.call(params)
      interactor = new(params)
      interactor.run
      interactor
    end

    attr_reader :activity_production, :error

    def initialize(params)
      @activity_production = params[:activity_production]
      @plot = params[:plot]
    end

    def run
      # Destroy all the precedents daily charges for the activity_production
      destroy_daily_charges
      destroy_intervention_proposal
      return unless @activity_production.technical_itinerary.present?

      begin
        unless @activity_production.batch_planting?
          TechnicalItineraries::DailyCharges::DefaultCreationService
            .new(@activity_production)
            .perform

          return
        end

        if @activity_production.batch.irregular_batch?
          TechnicalItineraries::DailyCharges::IrregularBatchCreationService
            .new(@activity_production)
            .perform

          return
        end

        TechnicalItineraries::DailyCharges::BatchCreationService
          .new(@activity_production)
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

      def destroy_daily_charges
        DailyCharge
          .of_activity_production(@activity_production)
          .destroy_all
      end

      def destroy_intervention_proposal
        InterventionProposal
          .where(activity_production: @activity_production)
          .where.not(id: ::Intervention.where('intervention_proposal_id IS NOT NULL').map(&:intervention_proposal_id))
          .destroy_all
      end
  end
end
