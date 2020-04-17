class FixedAsset
  module Transitions
    class StartUp < Transitionable::Transition
      event :start_up
      from :draft, :waiting
      to :in_use

      def initialize(fixed_asset, **_options)
        super fixed_asset
      end

      def transition
        resource.state = :in_use
        resource.transaction do
          resource.save!
          depreciate_imported_depreciations!
          # TODO reverse this method, send an information message with the born_at of the product
          # update_product_born_at!
        end
        true
      rescue
        false
      end

      def can_run?
        super && resource.valid? &&
          during_or_before_opened_financial_year?(resource.started_on)
      end

      private

        def during_or_before_opened_financial_year?(date)
          opened_fys = FinancialYear.opened

          opened_fys.any? && date <= opened_fys.last.stopped_on
        end

        def depreciate_imported_depreciations!
          resource.depreciations.up_to(FinancialYear.opened.first.started_on).map { |fad| fad.update!(accountable: true, locked: true) }
        end

        # TODO send a message instead
        def update_product_born_at!
          return unless resource.product
          resource.product.update!(born_at: resource.started_on.to_datetime)
        end
    end
  end
end
