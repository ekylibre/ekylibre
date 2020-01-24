module Api
  module V1
    class ProductsController < Api::V1::BaseController
      ACCEPTED_TYPES = %w(Worker Equipment LandParcel BuildingDivision Plant Matter)
      NESTED_INCLUDE_ASSOCIATION = { LandParcel: { activity_production: :activity } }
      def index
        type = params[:product_type] && params[:product_type].to_s.singularize.camelize

        products = if type.blank?
          Product.where(type: ACCEPTED_TYPES)
        elsif ACCEPTED_TYPES.include?(type)
          Product.where(type: type)
        else
          nil
        end
        return error_message("Invalid type: #{type}, accepted types are: #{ACCEPTED_TYPES.join(',')}") if products.nil?

        if params[:modified_since]
          products = products.where('updated_at > ?', params[:modified_since].to_datetime)
        end

        NESTED_INCLUDE_ASSOCIATION.each do |type, association|
          type_class = type.to_s.constantize
          next if products.none? { |p| p.is_a?(type_class) }
          products = products.includes(association)
        end

        render 'api/v1/products/index.json', locals: { products: products }
      end
    end
  end
end
