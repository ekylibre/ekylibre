module Api
  module V1
    module Lexicon
      class EphyCropsetsController < ApiPhytosanitaryDataController
        def index
          paginated_result(EphyCropset, order: :id)
        end

        def create
          @removed, @updated = compute_diff(permitted_params, model: EphyCropset, table_name: table_name)
        end
      end
    end
  end
end
