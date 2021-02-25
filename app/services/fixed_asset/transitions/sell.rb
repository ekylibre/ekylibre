# frozen_string_literal: true

class FixedAsset
  module Transitions
    class Sell < Transitionable::Transition
      include Depreciable

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
          active = resource.depreciation_on @sold_on
          split_depreciation! active, @sold_on if active && @sold_on < active.stopped_on

          resource.depreciations.up_to(@sold_on).each { |d| d.update! accountable: true }

          resource.update! state: :sold

          resource.depreciations.following(active).destroy_all if active

          resource.depreciations.update_all locked: true

          resource.sale.invoice unless resource.sale.invoice?

          resource.product.reload
          resource.product.update! dead_at: @sold_on
          true
        end
      end

      def can_run?
        super && resource.valid? &&
          FinancialYear.on(@sold_on)&.opened? &&
          depreciations_valid?(@sold_on) &&
          resource.product &&
          resource.sale
      end
    end
  end
end
