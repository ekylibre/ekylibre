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
        new_intervention.validator = validator
      end

      if intervention.nature == :request
        new_intervention.request_intervention_id = intervention.id
      end

      new_intervention.state = new_state
      new_intervention.nature = :record

      return if new_intervention.invalid?

      new_intervention.save!
      new_intervention
    end

    private

      attr_reader :intervention, :new_state, :delete_option, :validator
      attr_writer :new_intervention

      def new_intervention
        @new_intervention ||= BuildDuplicate.call(intervention)
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
