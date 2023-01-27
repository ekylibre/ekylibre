# frozen_string_literal: true

module Interventions
  class ChangeState
    def initialize(intervention:, new_state:, delete_option: nil, validator: nil)
      @intervention = intervention
      @new_state = new_state
      @delete_option = delete_option&.to_sym
      @validator = validator
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      return if intervention.request? && intervention.record_interventions.any?

      intervention_to_update = intervention

      if intervention.nature == :request
        intervention_to_update = build_duplicate_intervention
        intervention_to_update.request_intervention_id = intervention.id
      end

      case new_state
      when :rejected
        case intervention.nature.to_sym
        when :record
          handle_rejected_record
          return
        when :request
          handle_rejected_request
          return
        end
      when :validated
        intervention_to_update.validator = validator
      end

      intervention_to_update.state = new_state
      intervention_to_update.nature = :record

      return if intervention_to_update.invalid?

      intervention_to_update.save!
      intervention_to_update
    end

    private

      attr_reader :intervention, :new_state, :delete_option, :validator

      def build_duplicate_intervention
        BuildDuplicate.call(intervention)
      end

      def handle_rejected_record
        if (intervention_request = intervention.request_intervention).present?
          if delete_option == :delete_request
            intervention_request.destroy!
          else
            intervention_request.parameters = intervention.parameters
            intervention_request.save!
          end
        end

        intervention.destroy!
      end

      def handle_rejected_request
        intervention.state = new_state
        return unless intervention.valid?

        intervention.save!
      end

  end
end
