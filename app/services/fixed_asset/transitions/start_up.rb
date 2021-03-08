class FixedAsset
  module Transitions
    class StartUp < Transitionable::Transition
      event :start_up
      from :draft, :waiting
      to :in_use

      def initialize(resource, started_on: nil, **)
        super(resource)

        @started_on = resource.started_on || started_on
      end

      def transition
        resource.started_on = started_on
        resource.state = :in_use
        resource.transaction do
          resource.save!
          depreciate_imported_depreciations!
          # TODO: reverse this method, send an information message with the born_at of the product
          # update_product_born_at!
        end
      end

      def can_run?
        super && resource.valid? &&
          during_or_before_opened_financial_year?(started_on)
      end

      private

        # @return [Date]
        attr_reader :started_on

        def during_or_before_opened_financial_year?(date)
          opened_fys = FinancialYear.opened

          opened_fys.any? && date <= opened_fys.last.stopped_on
        end

        def depreciate_imported_depreciations!
          resource.depreciations.up_to(FinancialYear.opened.first.started_on).map { |fad| fad.update!(accountable: true, locked: true) }
        end

        # TODO: send a message instead
        def update_product_born_at!
          if resource.product.present?
            resource.product.update!(born_at: resource.started_on.to_datetime)
          end
        end
    end
  end
end
