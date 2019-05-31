class FixedAsset
  module Transitions
    class Scrap < Transitionable::Transition
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
          active = resource.depreciations.on @scrapped_on
          split_depreciation! active, @scrapped_on unless active.stopped_on == @scrapped_on

          # Bookkeep normally the depreciations before the scrap date
          resource.depreciations.up_to(@scrapped_on).each { |d| d.update! accountable: true }

          resource.update! state: :scrapped

          # Bookkeep the following with a FixedAsset marked as scrapped
          resource.depreciations.following(active).each { |d| d.update! accountable: true, fixed_asset: resource }

          # Lock all depreciations as the scrap transition is not-reversible
          resource.depreciations.update_all locked: true

          resource.product.update! dead_at: @scrapped_on
          true
        end
      end

      def can_run?
        super && resource.valid? &&
          scrapped_on_during_opened_financial_year &&
          depreciations_valid?(@scrapped_on) &&
          resource.product
      end

      private

        def split_depreciation!(depreciation, date)
          total_amount = depreciation.amount
          period = Accountancy::Period.new(depreciation.started_on, depreciation.stopped_on)
          before, after = period.split date

          depreciation.update! stopped_on: before.stop,
                               amount: round(total_amount * before.days / period.days)

          shift_depreciations! resource.depreciations.following(depreciation)
          resource.depreciations.create! position: depreciation.position + 1,
                                         amount: total_amount - depreciation.amount,
                                         started_on: after.start,
                                         stopped_on: after.stop
        end

        def round(amount)
          resource.currency.to_currency.round amount
        end

        def shift_depreciations!(depreciations)
          depreciations.each { |d| d.update! position: d.position + 1 }
        end

        def depreciations_valid?(scrap_date)
          active = resource.depreciations.on scrap_date
          active.nil? || resource.depreciations.following(active).all? { |d| !d.has_journal_entry? }
        end

        def scrapped_on_during_opened_financial_year
          FinancialYear.on(@scrapped_on)&.opened?
        end

    end
  end
end