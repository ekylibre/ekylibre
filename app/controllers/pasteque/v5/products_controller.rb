class Pasteque::V5::ProductsController < Pasteque::V5::BaseController
  manage_restfully only: [:index, :show], model: :product_nature_variant, scope: :saleables

  def category
    @records = ProductNatureVariant.of_category(params[:id]).saleables
    render template: "layouts/pasteque/v5/index", locals:{output_name: "product", partial_path: 'products/product'}
  end
end
