module Calculus
  module TaxedAmounts

    class Default < Base

      OPS = {
        quantity_tax: {
          amount: [:a, :b, :c],
          pretax_amount: [:d, :b, :c],
          unit_amount: [:e, :g, :d],
          unit_pretax_amount: [:f, :g, :d],
        },
        tax_quantity: {
          amount: [:b, :e, :g],
          pretax_amount: [:c, :f, :h],
          unit_amount: [:h, :e, :g],
          unit_pretax_amount: [:g, :f, :h],
        }
      }

      def operations
        OPS
      end

      # Compute amounts using different methods
      # This methods doesn't save results. It computes values
      def compute
        # @item.reduction_percentage ||= 0
        # @item.quantity ||= 0

        # reduction_rate = (100.0 - @item.reduction_percentage) / 100.0

        unless tax
          raise "Need tax for amount computation"
        end

        unless computation_method
          raise "Cannot find computation method"
        end

        unless reference_value
          raise "Cannot find reference value"
        end

        unless starts = operations[computation_method]
          raise "Unknown computation method: #{computation_method.inspect}"
        end
        unless ops = starts[reference_value]
          raise "Unknown reference value in #{computation_method}: #{reference_value.inspect}"
        end
        # Execute basic operation in right order
        # puts "Compute #{self.class.name.blue} #{computation_method.to_s.red} from #{reference_value.to_s.green}"
        ops.each do |op|
          # puts "Compute basic #{op.to_s.yellow}"
          self.send("compute_basic_#{op}")
        end

        # @item.unit_amount   = @item.tax.amount_of(@item.unit_pretax_amount).round(precision)
        # @item.pretax_amount = (@item.quantity * @item.unit_pretax_amount * reduction_rate).round(precision)
        # if @item.computation_method_quantity_tax? or adaptative_method == :quantity_tax
        #   @item.amount      = @item.tax.amount_of(@item.pretax_amount).round(precision)
        # elsif @item.computation_method_tax_quantity? or adaptative_method == :tax_quantity
        #   @item.amount      = (@item.quantity * @item.unit_amount * reduction_rate).round(precision)
        # end

        # @item.reduced_unit_pretax_amount = (@item.unit_pretax_amount * (100.0 - @item.reduction_percentage) / 100.0)
        # @item.reduced_unit_amount = (@item.unit_amount * (100.0 - @item.reduction_percentage) / 100.0)
      end

    end

  end
end
