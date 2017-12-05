# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
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
  class ParcelsController < Backend::BaseController
    before_action only: :new do
      params[:nature] ||= 'incoming'
    end

    protected

    def find_parcels
      parcel_ids = params[:id].split(',')
      parcels = parcel_ids.map { |id| Parcel.find_by(id: id) }.compact
      unless parcels.any?
        notify_error :no_parcels_given
        redirect_to(params[:redirect] || { action: :index })
        return nil
      end
      parcels
    end
  end
end
