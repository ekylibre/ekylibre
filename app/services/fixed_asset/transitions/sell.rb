class FixedAsset
  module Transitions
    class Sell < Transitionable::Transition
      event :sell
      from :in_use
      to :sold

      def initialize(fixed_asset, sold_on, **_options)
        super fixed_asset

        @sold_on = fixed_asset.sold_on || sold_on
      end

      def transition
        resource.sold_on ||= @sold_on
        resource.transaction do
          active = resource.depreciations.on @sold_on
          split_depreciation! active, @sold_on unless active.stopped_on == @sold_on

          resource.depreciations.up_to(@sold_on).each { |d| d.update! accountable: true }

          resource.update! state: :sold

          resource.depreciations.following(active).destroy_all

          resource.depreciations.update_all locked: true

          resource.sale.invoice unless resource.sale.invoice?

          resource.product.update! dead_at: @sold_on
          true
        end
      end

      def can_run?
        super && resource.valid? &&
          sold_on_during_opened_financial_year &&
          resource.product &&
          resource.sale
      end

      private

        def sold_on_during_opened_financial_year
          FinancialYear.on(@sold_on)&.opened?
        end
    end
  end
end
