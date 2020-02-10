module Api
  module V1
    module Lexicon
      class RegisteredPhytosanitaryProductsController < ApiPhytosanitaryDataController
        def index
          @removed, @updated = compute_diff([], model: RegisteredPhytosanitaryProduct, table_name: table_name)
        end

        def create
          @removed, @updated = compute_diff(permitted_params, model: RegisteredPhytosanitaryProduct, table_name: table_name)

          render "index"
        end
      end
    end
  end
end
