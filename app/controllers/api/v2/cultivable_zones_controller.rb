module Api
  module V2
    class CultivableZonesController < Api::V2::BaseController

      def index
        @cultivable_zones = CultivableZone.all
      end

      def create
        cultivable_zone = CultivableZone.new(permitted_params.merge(creator_id: current_user.id))
        if cultivable_zone.save!
          render json: { uuid: cultivable_zone.uuid }, status: :created
        end
      end

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
