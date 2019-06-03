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
        resource.state = :sold
        resource.transaction do
          resource.save!
          resource.product.update! dead_at: @sold_on
          resource.sale.invoice unless resource.sale.invoice?
          update_depreciation_out_on! resource.sold_on
          true
        end
      rescue
        false
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

        def update_depreciation_out_on!(out_on)
          depreciation_out_on = resource.current_depreciation(out_on)
          return false if depreciation_out_on.nil?

          # check if depreciation have journal_entry
          if depreciation_out_on.journal_entry
            raise StandardError, "This fixed asset depreciation is already bookkeep ( Entry : #{depreciation_out_on.journal_entry.number})"
          end

          next_depreciations = resource.depreciations.following depreciation_out_on

          # check if next depreciations have journal_entry
          if next_depreciations.any?(&:journal_entry)
            raise StandardError, "The next fixed assets depreciations are already bookkeep ( Entry : #{d.journal_entry.number})"
          end

          # stop bookkeeping next depreciations
          next_depreciations.update_all(accountable: false, locked: true)

          # use amount to last bookkeep (net_book_value == current_depreciation.depreciable_amount)
          # use amount to last bookkeep (already_depreciated_value == current_depreciation.depreciated_amount)

          # compute part time

          first_period = out_on.day
          global_period = (depreciation_out_on.stopped_on - depreciation_out_on.started_on) + 1
          first_ratio = (first_period.to_f / global_period.to_f) if global_period
          # second_ratio = (1 - first_ratio)

          first_depreciation_amount_ratio = (depreciation_out_on.amount * first_ratio).round(2)
          # second_depreciation_amount_ratio = (depreciation_out_on.amount * second_ratio).round(2)

          # update current_depreciation with new value and bookkeep it
          depreciation_out_on.stopped_on = out_on
          depreciation_out_on.amount = first_depreciation_amount_ratio
          depreciation_out_on.accountable = true
          depreciation_out_on.save!

        end
    end
  end
end
