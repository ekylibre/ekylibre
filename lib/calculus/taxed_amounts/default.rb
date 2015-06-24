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
      # This method doesn't save results. It computes values
      def compute
        unless computation_method
          raise "Cannot find computation method"
        end

        return if computation_method == :manual

        unless tax
          raise "Need tax for amount computation"
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
        ops.each do |op|
          self.send("compute_basic_#{op}")
        end
      end

    end

  end
end
