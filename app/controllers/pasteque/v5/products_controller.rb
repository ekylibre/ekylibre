module Pasteque
  module V5
    class ProductsController < Pasteque::V5::BaseController
      manage_restfully only: [:index, :show], model: :product_nature_variant, scope: :saleables

      def category
        @records = ProductNatureVariant.of_category(params[:id]).saleables
        render template: 'index'
      end
    end
  end
end
