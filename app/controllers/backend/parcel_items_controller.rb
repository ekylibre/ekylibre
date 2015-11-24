# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2013 Brice Texier
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
  class ParcelItemsController < Backend::BaseController
    def new
      if request.xhr? && params[:variant_id]
        unless @parcel = Parcel.find_by(id: params[:parcel_id])
          @parcel = Parcel.new
        end
        return unless variant = find_and_check(:product_nature_variant, params[:variant_id])
        params[:external] ||= false
        @parcel.items.build(product_nature_variant_id: variant.id) # (id: rand(1_000_000_000))
        render partial: 'nested_form'
      else
        redirect_to backend_root_url
      end
    end
  end
end
