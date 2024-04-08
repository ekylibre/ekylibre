module Backend
  module Cells
    class TaxBalanceCellsController < Backend::Cells::BaseController
      def show
        f = current_user.current_financial_year
        if f
          @financial_year = f
          @started_on = f.started_on
          @stopped_on = f.stopped_on
          @vat_declarations = TaxDeclaration.where(financial_year: @financial_year)
          @vat_declarations_balance = @vat_declarations.map{|d| d.global_balance.round}.compact.sum
          @vat_payments = TaxPayment.where(financial_year: @financial_year)
          @vat_payments_balance = @vat_payments.map(&:relative_amount).compact.sum
          @vat_global_balance = (@vat_declarations_balance.to_d + @vat_payments_balance.to_d).round(2)
          @result_class = if @vat_global_balance > 0
                            :negative
                          elsif @vat_global_balance < 0
                            :positive
                          else
                            :caution
                          end
        end
      end
    end
  end
end
