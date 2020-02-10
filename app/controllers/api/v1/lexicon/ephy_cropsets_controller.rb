module Api
  module V1
    module Lexicon
      class EphyCropsetsController < ApiPhytosanitaryDataController
        def index
          @removed, @updated = compute_diff([], model: EphyCropset, table_name: table_name)
        end

        def create
          @removed, @updated = compute_diff(permitted_params, model: EphyCropset, table_name: table_name)

          render "index"
        end
      end
    end
  end
end
