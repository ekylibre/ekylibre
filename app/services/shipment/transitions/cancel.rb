# frozen_string_literal: true

class Shipment
  module Transitions
    # Unlike every other transition, `cancel` steps back to a different state
    # depending on where it starts from, exactly as the state_machine event did:
    # ordered -> draft, in_preparation -> ordered.
    # Hence the `to_for` override — `to` alone cannot express it.
    class Cancel < Transitionable::Transition
      DESTINATIONS = { ordered: :draft, in_preparation: :ordered }.freeze

      event :cancel
      from(*DESTINATIONS.keys)
      to DESTINATIONS.values.first

      # @param source [Symbol] state the resource is currently in
      # @return [Symbol, nil]
      def self.to_for(source)
        DESTINATIONS[source.to_sym]
      end

      def transition
        destination = self.class.to_for(resource.state)
        raise "No cancel destination from #{resource.state}" if destination.nil?

        resource.state = destination
        resource.save!
      end
    end
  end
end
