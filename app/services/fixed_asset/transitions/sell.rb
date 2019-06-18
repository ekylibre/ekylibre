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
          active = resource.depreciation_on @sold_on
          split_depreciation! active, @sold_on if active && @sold_on < active.stopped_on

          resource.depreciations.up_to(@sold_on).each { |d| d.update! accountable: true }

          resource.update! state: :sold

          resource.depreciations.following(active).destroy_all if active

          resource.depreciations.update_all locked: true

          resource.sale.invoice unless resource.sale.invoice?

          resource.product.update! dead_at: @sold_on
          true
        end
      end

      def can_run?
        super && resource.valid? &&
          sold_on_during_opened_financial_year(@sold_on) &&
          depreciations_valid?(@sold_on) &&
          resource.product &&
          resource.sale
      end

      private

        def split_depreciation!(depreciation, date)
          total_amount = depreciation.amount
          period = Accountancy::Period.new(depreciation.started_on, depreciation.stopped_on)
          before, after = period.split date

          depreciation.update! stopped_on: before.stop,
                               amount: round(total_amount * before.days / period.days)

          resource.depreciations.create! position: depreciation.position + 1,
                                         amount: total_amount - depreciation.amount,
                                         started_on: after.start,
                                         stopped_on: after.stop
        end

        def round(amount)
          resource.currency.to_currency.round amount
        end

        def depreciations_valid?(date)
          active = resource.depreciation_on date
          active.nil? || resource.depreciations.following(active).all? { |d| !d.has_journal_entry? }
        end

        def sold_on_during_opened_financial_year(date)
          FinancialYear.on(date)&.opened?
        end
    end
  end
end
