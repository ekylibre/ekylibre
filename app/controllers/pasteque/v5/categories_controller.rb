module Pasteque
  module V5
    class CategoriesController < Pasteque::V5::BaseController
      manage_restfully only: [:index, :show], model: :product_nature_category, scope: :with_sale_catalog_items

      # No children for categories for now
      def children
        render json: { status: 'ok', content: [] }
      end
    end
  end
end
