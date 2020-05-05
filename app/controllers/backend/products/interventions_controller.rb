# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2014 Sebastien Gauvrit, Brice Texier
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

module Backend
  module Products
    class InterventionsController < Backend::BaseController
      def has_harvesting
        product = Product.find_by(id: params[:id])
        intervention_started_at = Time.parse(params[:intervention_started_at])

        if product.present?
          harvesting_count = ::Interventions::HarvestInProgressQuery
                               .call(Intervention, product, intervention_started_at)
                               .count

          render json: { has_harvesting: harvesting_count > 0 ? true : false }
        else
          render json: { error: { message: "Cannot find product of id='#{params[:id]}'" } }, status: :not_found
        end
      end

      private

        def permitted_params
          params.permit(:id, :intervention_started_at)
        end
    end
  end
end
