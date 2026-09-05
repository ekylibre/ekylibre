module Api
  module V2
    class ProductsController < Api::V2::BaseController
      ACCEPTED_TYPES = %w[Animal Worker Equipment LandParcel BuildingDivision Plant Matter].freeze
      NESTED_INCLUDE_ASSOCIATION = { LandParcel: { activity_production: :activity } }.freeze

      # GET /api/v2/products(/:product_type)
      # Lists products, optionally filtered by type. Supported types are:
      # Animal, Worker, Equipment, LandParcel, BuildingDivision, Plant, Matter.
      #
      # Authentication: required.
      #
      # URL params:
      # - product_type [String, optional] One of the accepted types
      #
      # Query string params:
      # - modified_since [ISO8601 datetime, optional] Returns only products updated after this date
      #
      # Responses:
      # - 200 OK         Array of products (Jbuilder template)
      # - 400 Bad Request When product_type is invalid
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

        render 'api/v2/products/index.json', locals: { products: products }
      end
    end
  end
end
