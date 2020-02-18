module Api
  module V1
    module Lexicon
      class RegisteredPhytosanitaryProductsController < ApiPhytosanitaryDataController
        def index
          paginated_result(RegisteredPhytosanitaryProduct, order: :id)
        end

        def create
          @removed, @updated = compute_diff(permitted_params, model: RegisteredPhytosanitaryProduct, table_name: table_name)
        end
      end
    end
  end
end
