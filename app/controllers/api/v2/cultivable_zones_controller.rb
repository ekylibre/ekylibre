module Api
  module V2
    class CultivableZonesController < Api::V2::BaseController

      # GET /api/v2/cultivable_zones
      # Lists all cultivable zones (parcels) of the current tenant.
      #
      # Authentication: required.
      #
      # Responses:
      # - 200 OK  Array of cultivable zones (Jbuilder template)
      def index
        @cultivable_zones = CultivableZone.all
      end

      # POST /api/v2/cultivable_zones
      # Creates a new cultivable zone identified by a UUID.
      #
      # Authentication: required.
      #
      # Request body params:
      # - uuid        [String, required] Client-generated UUID for the zone
      # - name        [String, required] Display name
      # - work_number [String, optional] Work number/code
      # - shape       [String/GeoJSON, optional] Geometry (WKT or GeoJSON)
      #
      # Responses:
      # - 201 Created   { "uuid": "<uuid>" }
      # - 403 Forbidden { "errors": [...] } when validation fails
      def create
        cultivable_zone = CultivableZone.new(permitted_params.merge(creator_id: current_user.id))
        if cultivable_zone.save!
          render json: { uuid: cultivable_zone.uuid }, status: :created
        end
      end

      # PUT/PATCH /api/v2/cultivable_zones/:uuid
      # Updates an existing cultivable zone identified by its UUID.
      #
      # Authentication: required.
      #
      # URL params:
      # - uuid [String, required] UUID of the zone to update
      #
      # Request body params (all optional):
      # - name        [String]
      # - work_number [String]
      # - shape       [String/GeoJSON]
      #
      # Responses:
      # - 200 OK        { "uuid": "<uuid>" }
      # - 404 Not Found Zone does not exist
      # - 403 Forbidden Validation failed
      def update
        cultivable_zone = CultivableZone.find_by(uuid: params[:uuid])
        if cultivable_zone.update!(permitted_params)
          render json: { uuid: cultivable_zone.uuid }, status: :ok
        end
      end

      protected

        def permitted_params
          params.permit(
            :uuid,
            :name,
            :work_number,
            :shape
          )
        end

    end
  end
end
