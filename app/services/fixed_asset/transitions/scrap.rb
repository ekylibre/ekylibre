class FixedAsset
  module Transitions
    class Scrap < Transitionable::Transition
      include Depreciable

      event :scrap
      from :in_use
      to :scrapped

      def initialize(fixed_asset, scrapped_on, **_options)
        super fixed_asset

        @scrapped_on = fixed_asset.scrapped_on || scrapped_on
      end

      def transition
        resource.scrapped_on ||= @scrapped_on
        resource.transaction do
          active = resource.depreciation_on @scrapped_on
          split_depreciation! active, @scrapped_on if active && @scrapped_on < active.stopped_on

          # Bookkeep normally the depreciations before the scrap date
          resource.depreciations.up_to(@scrapped_on).each { |d| d.update! accountable: true }

          resource.update! state: :scrapped

          # Bookkeep the following with a FixedAsset marked as scrapped
          resource.depreciations.following(active).each { |d| d.update! accountable: true, fixed_asset: resource } if active

          # Lock all depreciations as the scrap transition is not-reversible
          resource.depreciations.update_all locked: true

          resource.product.update! dead_at: @scrapped_on
          true
        end
      end

      def can_run?
        super && resource.valid? &&
          FinancialYear.on(@scrapped_on)&.opened? &&
          depreciations_valid?(@scrapped_on) &&
          resource.product
      end
    end
  end
end
