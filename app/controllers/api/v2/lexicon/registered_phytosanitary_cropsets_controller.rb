module Api
  module V2
    module Lexicon
      class RegisteredPhytosanitaryCropsetsController < ApiPhytosanitaryDataController
        # GET /api/v2/lexicon/registered_phytosanitary_cropsets
        # Returns the current dataset of registered phytosanitary cropsets.
        # If the client provides a `modified_since` date and the lexicon was not
        # updated since, the response is a single string (the date), telling the
        # client its local cache is up-to-date.
        #
        # Authentication: required.
        #
        # Query string params:
        # - modified_since [Date, optional] Last sync date (DD/MM/YYYY)
        # - paginate       [Any, optional]  Enable pagination if present
        # - page           [Integer, optional, default 1]
        # - per_page       [Integer, optional, default 100, max 1000]
        #
        # Responses:
        # - 200 OK  Either:
        #     - "DD/MM/YYYY" (string) if dataset already up-to-date
        #     - Array of cropsets, or paginated payload { data, pagination }
        def index
          return @updated_at if phytosanitary_updated_since?(params[:modified_since])

          paginated_result(RegisteredPhytosanitaryCropset, order: :id)
        end

        # POST /api/v2/lexicon/registered_phytosanitary_cropsets
        # Returns the diff between the client cache and the server (added,
        # updated, removed). Used by clients to keep their local copy in sync.
        #
        # Authentication: required.
        #
        # Request body params:
        # - data [Array<{ id, record_checksum }>] Client-side cache state
        #
        # Responses:
        # - 200 OK  { removed: [...], updated: [...] }
        def create
          @removed, @updated = compute_diff(permitted_params, model: RegisteredPhytosanitaryCropset, table_name: table_name)
        end
      end
    end
  end
end
