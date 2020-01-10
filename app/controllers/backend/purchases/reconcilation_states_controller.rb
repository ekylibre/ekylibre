# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2012-2013 David Joulin, Brice Texier
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
  module Purchases
    class ReconcilationStatesController < Backend::BaseController
      before_action :set_purchase, only: %i[put_reconcile_state put_to_reconcile_state put_accepted_state]

      def put_reconcile_state
        @purchase.update_column(:reconciliation_state, :reconcile)

        render json: @purchase.to_json
      end

      def put_to_reconcile_state
        @purchase.update_column(:reconciliation_state, :to_reconcile)

        render json: @purchase.to_json
      end

      def put_accepted_state
        @purchase.update_column(:reconciliation_state, :accepted)

        render json: @purchase.to_json
      end

      private

      def set_purchase
        return unless permitted_params.key?(:id)

        @purchase = Purchase.find(permitted_params[:id])
      end

      def permitted_params
        params.permit(:id)
      end
    end
  end
end
