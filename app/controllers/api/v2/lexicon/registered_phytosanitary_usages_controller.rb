module Api
  module V2
    module Lexicon
      class RegisteredPhytosanitaryUsagesController < Api::V2::Lexicon::ApiPhytosanitaryDataController
        # GET /api/v2/lexicon/registered_phytosanitary_usages
        # Returns the dataset of authorized phytosanitary usages (product/crop/dose).
        # When `user_product=true`, restricts to usages of the products
        # linked to the tenant's variants.
        #
        # Authentication: required.
        #
        # Query string params:
        # - modified_since [Date, optional]    Last sync date (DD/MM/YYYY)
        # - user_product   [String, optional]  "true" to filter on user products
        # - paginate       [Any, optional]
        # - page           [Integer, optional, default 1]
        # - per_page       [Integer, optional, default 100, max 1000]
        #
        # Responses:
        # - 200 OK  String, Array of usages, or paginated payload
        def index
          return @updated_at if phytosanitary_updated_since?(params[:modified_since])

          params[:user_product].present? && params[:user_product]=="true" ? user_phytosanitary_product_usage : paginated_result(RegisteredPhytosanitaryUsage, order: :id)
        end

        # POST /api/v2/lexicon/registered_phytosanitary_usages
        # Returns the sync diff for phytosanitary usages.
        #
        # Authentication: required.
        #
        # Request body params:
        # - data [Array<{ id, record_checksum }>]
        #
        # Responses:
        # - 200 OK  { removed: [...], updated: [...] }
        def create
          @removed, @updated = compute_diff(permitted_params, model: RegisteredPhytosanitaryUsage, table_name: table_name)
        end
      end
    end
  end
end
