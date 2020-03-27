module Api
  module V1
    module Lexicon
      class RegisteredPhytosanitaryCropsetsController < ApiPhytosanitaryDataController
        def index
          paginated_result(RegisteredPhytosanitaryCropset, order: :id)
        end

        def create
          @removed, @updated = compute_diff(permitted_params, model: RegisteredPhytosanitaryCropset, table_name: table_name)
        end
      end
    end
  end
end
