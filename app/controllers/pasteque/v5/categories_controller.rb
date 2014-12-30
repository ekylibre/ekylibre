class Pasteque::V5::CategoriesController < Pasteque::V5::BaseController
  manage_restfully only: [:index, :show], model: :product_nature_category
end
