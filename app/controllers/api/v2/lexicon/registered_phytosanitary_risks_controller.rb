module Api
  module V2
    module Lexicon
      class RegisteredPhytosanitaryRisksController < Api::V2::Lexicon::ApiPhytosanitaryDataController
        # GET /api/v2/lexicon/registered_phytosanitary_risks
        # Returns the dataset of phytosanitary risks (toxicity, hazard codes…).
        #
        # Authentication: required.
        #
        # Query string params:
        # - modified_since [Date, optional]
        # - paginate       [Any, optional]
        # - page           [Integer, optional, default 1]
        # - per_page       [Integer, optional, default 100, max 1000]
        #
        # Responses:
        # - 200 OK  String, Array of risks, or paginated payload
        def index
          return @updated_at if phytosanitary_updated_since?(params[:modified_since])

          paginated_result(RegisteredPhytosanitaryRisk, order: :id)
        end

        # POST /api/v2/lexicon/registered_phytosanitary_risks
        # Returns the sync diff for phytosanitary risks.
        #
        # Authentication: required.
        #
        # Request body params:
        # - data [Array<{ id, record_checksum }>]
        #
        # Responses:
        # - 200 OK  { removed: [...], updated: [...] }
        def create
          @removed, @updated = compute_diff(permitted_params, model: RegisteredPhytosanitaryRisk, table_name: table_name)
        end
      end
    end
  end
end
