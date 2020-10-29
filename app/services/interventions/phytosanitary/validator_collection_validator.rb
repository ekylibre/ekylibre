module Interventions
  module Phytosanitary
    class ValidatorCollectionValidator
      # @param [Array<ProductApplicationValidator>] children
      def initialize(*children)
        @children = children
      end
      # @param [Array<Models::ProductWithUsage>] products_usages
      # @return [Models::ProductApplicationResult]
      def validate(products_usages)
        @children
          .map { |c| c.validate(products_usages) }
          .reduce { |acc, result| acc.merge(result) }
      end
    end
  end
end