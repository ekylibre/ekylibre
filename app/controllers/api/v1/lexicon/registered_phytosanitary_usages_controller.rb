module Api
  module V1
    module Lexicon
      class RegisteredPhytosanitaryUsagesController < Api::V1::Lexicon::ApiPhytosanitaryDataController
        def index
          paginated_result(RegisteredPhytosanitaryUsage, order: :id)
        end

        def create
          @removed, @updated = compute_diff(permitted_params, model: RegisteredPhytosanitaryUsage, table_name: table_name)
        end
      end
    end
  end
end
