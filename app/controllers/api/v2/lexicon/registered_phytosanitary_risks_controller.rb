module Api
  module V2
    module Lexicon
      class RegisteredPhytosanitaryRisksController < Api::V2::Lexicon::ApiPhytosanitaryDataController
        # @param [:modified_since] [Date]
        # @return [Date] or [Array, Object] if modified_since < phytosanitary_updated_at
        def index
          return @updated_at if phytosanitary_updated_since?(params[:modified_since])

          paginated_result(RegisteredPhytosanitaryRisk, order: :id)
        end

        def create
          @removed, @updated = compute_diff(permitted_params, model: RegisteredPhytosanitaryRisk, table_name: table_name)
        end
      end
    end
  end
end
