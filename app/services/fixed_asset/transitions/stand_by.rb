class FixedAsset
  module Transitions
    class StandBy < Transitionable::Transition
      event :stand_by
      from :draft
      to :waiting

      def initialize(fixed_asset, waiting_on, **_options)
        super fixed_asset
        @waiting_on = fixed_asset.waiting_on || waiting_on
      end

      def transition
        resource.state = :waiting
        resource.transaction do
          resource.save!
        end
        true
      rescue
        false
      end

      def can_run?
        super && resource.valid? &&
          FinancialYear.on(@waiting_on)&.opened?
      end
    end
  end
end
