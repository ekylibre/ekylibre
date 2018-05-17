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
    class IndicatorsController < Backend::BaseController
      def variable_indicators
        product = Product.find(params[:id])

        render json: { variable_indicators: product.variant.variable_indicators_list,
                       is_hour_counter: product.decorate.hour_counter? }
      end

      private

      def permitted_params
        params.permit(:id)
      end
    end
  end
end
