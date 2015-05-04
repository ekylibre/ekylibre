module Calculus
  module TaxedAmounts

    class Credit < Default

      OPS = {
        quantity_tax: {
          amount: [:a, :j],
          pretax_amount: [:d, :j],
          quantity: [:g, :d]
        },
        tax_quantity: {
          amount: [:i, :g],
          pretax_amount: [:j, :h],
          quantity: [:h, :g]
        }
      }

      def operations
        OPS
      end

    end

  end
end
