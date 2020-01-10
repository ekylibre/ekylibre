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
  module Variants
    class FixedAssetsController < Backend::BaseController
      before_action :set_variant, only: [:fixed_assets_datas]

      def fixed_assets_datas
        return render json: { error: 'No variant with this id' } if @variant.nil?

        fixed_assets_datas = {
          asset_account_id: @variant.fixed_asset_account&.id,
          expenses_account_id: @variant.fixed_asset_expenses_account&.id,
          depreciation_method: @variant.fixed_asset_depreciation_method,
          depreciation_percentage: @variant.fixed_asset_depreciation_percentage
        }

        render json: fixed_assets_datas
      end

      private

      def set_variant
        return unless permitted_params.key?(:id)

        @variant = ProductNatureVariant.find(permitted_params[:id])
      end

      def permitted_params
        params.permit(:id)
      end
    end
  end
end
