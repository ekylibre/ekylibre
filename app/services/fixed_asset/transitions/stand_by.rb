# frozen_string_literal: true

class FixedAsset
  module Transitions
    class StandBy < Transitionable::Transition
      event :stand_by
      from :draft
      to :waiting

      def initialize(fixed_asset, waiting_on: nil, **)
        super

        @waiting_on = fixed_asset.waiting_on || waiting_on
      end

      def transition
        resource.waiting_on = waiting_on
        resource.state = :waiting
        resource.save!
      end

      def can_run?
        super && resource.valid? &&
          FinancialYear.on(waiting_on)&.opened?
      end

      private

        # @return [Date]
        attr_reader :waiting_on
    end
  end
end
