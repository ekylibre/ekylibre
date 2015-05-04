module Calculus
  module TaxedAmounts

    class Base
      attr_reader :item

      delegate :amount, :pretax_amount, :unit_amount, :unit_pretax_amount, :tax, :quantity, to: :item


      def initialize(item)
        @item = item
      end

      def compute
        raise NotImplementedError
      end

      def computation_method
        unless @computation_method
          @item.computation_method ||= :adaptative
          if @item.computation_method_adaptative?
            if @item.unit_pretax_amount >= 10 ** @item.tax.amount.decimal_count
              @computation_method = :tax_quantity
            else
              @computation_method = :quantity_tax
            end
          else
            @computation_method = @item.computation_method
          end
          @computation_method = @computation_method.to_sym
        end
        return @computation_method
      end

      def reference_value
        unless @reference_value
          @item.reference_value ||= [:amount, :pretax_amount, :unit_amount, :unit_pretax_amount].detect do |x|
            !@item.send(x).nil?
          end
          @reference_value = @item.reference_value.to_sym
        end
        return @reference_value
      end

      def precision
        @precision ||= (currency ? currency.precision : 2)
      end

      def currency
        @currency ||= (@item.currency ? Nomen::Currencies[@item.currency] : nil)
      end

      def reduction_rate
        @reduction_rate ||= (100.0 - @item.reduction_percentage) / 100.0
      end

      def tax_ratio
        @tax_ratio ||= (100.0 + @item.tax.amount) / 100.0
      end

      def divide(recipient, numerator, denominator)
        value = self.send(numerator) / self.send(denominator)
        @item.send("#{recipient}=", value.round(precision))
      end

      def multiply(recipient, operand, coefficient)
        value = self.send(operand) * self.send(coefficient)
        @item.send("#{recipient}=", value.round(precision))
      end

      def compute_basic_a
        divide :pretax_amount, :amount, :tax_ratio
      end

      def compute_basic_b
        divide :unit_amount, :amount, :quantity
      end

      def compute_basic_c
        divide :unit_pretax_amount, :unit_amount, :quantity
      end

      def compute_basic_d
        multiply :amount, :pretax_amount, :tax_ratio
      end

      def compute_basic_e
        divide :unit_pretax_amount, :unit_amount, :tax_ratio
      end

      def compute_basic_f
        multiply :unit_amount, :unit_pretax_amount, :tax_ratio
      end

      def compute_basic_g
        multiply :pretax_amount, :unit_pretax_amount, :quantity
      end

      def compute_basic_h
        multiply :amount, :unit_amount, :quantity
      end

      def compute_basic_i
        divide :quantity, :amount, :unit_amount
      end

      def compute_basic_j
        divide :quantity, :pretax_amount, :unit_pretax_amount
      end

    end

  end
end
