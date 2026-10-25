module Api
  module V2
    module Lexicon
      class RegisteredPhytosanitaryProductsController < ApiPhytosanitaryDataController
        # GET /api/v2/lexicon/registered_phytosanitary_products
        # Returns registered phytosanitary products. When `user_product=true`,
        # filters to only the products linked to the tenant's variants.
        #
        # Authentication: required.
        #
        # Query string params:
        # - modified_since [Date, optional]    Last sync date (DD/MM/YYYY)
        # - user_product   [String, optional]  "true" to filter on user products
        # - paginate       [Any, optional]     Enable pagination if present
        # - page           [Integer, optional, default 1]
        # - per_page       [Integer, optional, default 100, max 1000]
        #
        # Responses:
        # - 200 OK  String (cache hit), Array of products, or paginated payload
        def index
          return @updated_at if phytosanitary_updated_since?(params[:modified_since])

          params[:user_product].present? && params[:user_product]=='true' ? user_phytosanitary_product : paginated_result(RegisteredPhytosanitaryProduct, order: :id)

        end

        # POST /api/v2/lexicon/registered_phytosanitary_products
        # Returns the sync diff for phytosanitary products.
        #
        # Authentication: required.
        #
        # Request body params:
        # - data [Array<{ id, record_checksum }>]
        #
        # Responses:
        # - 200 OK  { removed: [...], updated: [...] }
        def create
          @removed, @updated = compute_diff(permitted_params, model: RegisteredPhytosanitaryProduct, table_name: table_name)
        end

        private

          # As pkey is not string, need to cast
          def get_removed_element(elements, table_name:)
            return [] if elements.empty?

            ids = elements.map { |e| "(#{quote(e[:id])}::integer)" }.join(',')
            ApplicationRecord.connection.execute("SELECT t.id FROM  (values #{ids}) as t(id) WHERE t.id not in (SELECT id from #{table_name})").to_a
          end
      end
    end
  end
end
