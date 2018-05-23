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
        product = Product.find(permitted_params[:id])
        intervention_started_at = Time.parse(permitted_params[:intervention_started_at])

        harvesting_count = product
                           .interventions
                           .select{ |intervention| intervention.procedure.of_category?(:harvesting) && intervention.started_at < intervention_started_at }
                           .count

        render json: { has_harvesting: harvesting_count > 0 ? true : false }
      end

      private

      def permitted_params
        params.permit(:id, :intervention_started_at)
      end
    end
  end
end
