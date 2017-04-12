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
  class EventParticipationsController < Backend::BaseController
    def index
      redirect_to backend_events_path
    end

    def show
      if @event_participation = EventParticipation.find_by(id: params[:id])
        redirect_to backend_event_path(@event_participation.event_id)
      else
        redirect_to backend_root_path
      end
    end

    manage_restfully except: %i[index show], t3e: { participant_name: :participant_name }, redirect_to: { controller: :events, action: :show, id: 'RECORD.event_id'.c }, destroy_to: { controller: :events, action: :show, id: 'RECORD.event_id'.c }
  end
end
