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
  class EventsController < Backend::BaseController
    manage_restfully except: :index, nature: '(params[:nature] || Event.nature.default_value)'.c, started_at: 'Time.zone.now'.c, affair_id: 'params[:affair_id]'.c, participations_attributes: '(params[:participations] || [])'.c

    unroll

    autocomplete_for :place

    list(conditions: search_conditions(events: %i[duration place name description started_at]), order: { started_at: :desc }) do |t|
      t.action :edit
      t.action :destroy
      t.column :name, url: true
      t.column :casting
      t.column :duration
      t.column :place
      t.column :nature
      t.column :started_at
    end

    def index
      started_on = (params[:started_on] ? Time.new(*params[:started_on].split('-')) : Time.zone.now)
      @events = Event.between(started_on.beginning_of_month.beginning_of_week, started_on.end_of_month.end_of_week).includes(participations: [:participant])
      render partial: 'month' if request.xhr? && params[:started_on]
    end

    def change_minutes
      return unless nature = Nomen::EventNature[params[:nature]]
      value = nature.send(params[:field] || :name)
      render text: value.to_s, layout: false
    end

    list(:participations, model: :event_participations, conditions: { event_id: 'params[:id]'.c }, order: :id) do |t|
      t.action :edit
      t.action :destroy
      t.column :participant, url: true
      t.column :state
    end
  end
end
