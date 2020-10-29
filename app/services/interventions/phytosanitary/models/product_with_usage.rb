module Interventions
  module Phytosanitary
    module Models
      class ProductWithUsage
        include Ekylibre::Model
        include ActiveModel::Validations

        attr_reader :product, :usage

        # @param [Product] product
        # @param [RegisteredPhytosanitaryUsage] usage
        def initialize(product, usage)
          @product = product
          @usage = usage
        end
      end
    end
  end
end