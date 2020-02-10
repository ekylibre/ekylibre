module Api
  module V1
    module Lexicon
      class RegisteredPhytosanitaryRisksController < Api::V1::Lexicon::ApiPhytosanitaryDataController
        def index
          @removed, @updated = compute_diff([], model: RegisteredPhytosanitaryRisk, table_name: table_name)
        end

        def create
          @removed, @updated = compute_diff(permitted_params, model: RegisteredPhytosanitaryRisk, table_name: table_name)

          render "index"
        end
      end
    end
  end
end
