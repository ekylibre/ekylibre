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
    class SearchVariantsController < Backend::BaseController
      def search_by_expression
        result = []
        scope = search_params[:scope]
        input_text = search_params[:q]
        is_tool_or_doer = search_params[:is_tool_or_doer]
        max = search_params[:max]

        relation = ProductNature if is_tool_or_doer.to_b
        relation = ProductNatureVariant unless is_tool_or_doer.to_b

        results = ::Products::SearchVariantByExpressionQuery.call(relation, scope, input_text, max)

        render json: results.map { |result| { id: result.id, label: result.name.mb_chars.upcase } }
      end

      private

      def search_params
        params.permit(:scope,
                      :is_tool_or_doer,
                      :q,
                      :max)
      end
    end
  end
end
