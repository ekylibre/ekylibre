module Api
  module V2
    module Lexicon
      class RegisteredPhytosanitaryUsagesController < Api::V2::Lexicon::ApiPhytosanitaryDataController
        # @param [:modified_since] [Date]
        # @param [:user_product] [String]
        # @return [Date] or [Array, Object] if modified_since < phytosanitary_updated_at
        def index
          return @updated_at if phytosanitary_updated_since?(params[:modified_since])

          params[:user_product].present? && params[:user_product]=="true" ? user_phytosanitary_product_usage : paginated_result(RegisteredPhytosanitaryUsage, order: :id)
        end

        def create
          @removed, @updated = compute_diff(permitted_params, model: RegisteredPhytosanitaryUsage, table_name: table_name)
        end
      end
    end
  end
end
