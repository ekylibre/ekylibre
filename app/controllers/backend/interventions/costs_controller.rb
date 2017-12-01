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
  module Interventions
    class CostsController < Backend::BaseController
      def parameter_cost
        amount_interactor = ::Interventions::ParameterAmountInteractor
                            .call(costs_params)

        render json: { human_amount: amount_interactor.human_amount } if amount_interactor.success?
        render json: { human_amount: amount_interactor.failed_amount_computation } if amount_interactor.fail?
      end

      private

      def costs_params
        params.require(:intervention).permit(:intervention_id,
                                             :product_id,
                                             :quantity,
                                             :unit_name,
                                             :intervention_started_at,
                                             :intervention_stopped_at)
      end
    end
  end
end
