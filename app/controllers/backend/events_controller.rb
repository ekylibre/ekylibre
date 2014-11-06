# -*- coding: utf-8 -*-
# == License
# Ekylibre ERP - Simple agricultural ERP
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

class Backend::EventsController < BackendController
  manage_restfully except: :index, nature: "Event.nature.default_value".c, :started_at => "Time.now".c

  unroll

  autocomplete_for :place

  list(conditions: search_conditions(events: [:duration, :place, :name, :description, :started_at]), order: {started_at: :desc}) do |t|
    t.column :name
    t.column :casting
    t.column :duration
    t.column :place
    t.column :nature
    t.column :started_at
    t.action :edit
    t.action :destroy
  end

  def index
    year  = params[:year]  || Date.today.year
    month = params[:month] || Date.today.month
    started_at = Time.new(year.to_i, month.to_i, 1)
    @events = Event.between(started_at, started_at.end_of_month)
    if request.xhr? and params[:year] and params[:month]
      render partial: "month"
    end
  end

  def change_minutes
    return unless nature = Nomen::EventNatures[params[:nature]]
    value = nature.send(params[:field] || :name)
    render :text => value.to_s, :layout => false
  end

  list(:participations, model: :event_participations, conditions: {event_id: 'params[:id]'.c}, order: :id) do |t|
    t.column :participant, url: true
    t.column :state
    t.action :edit
    t.action :destroy
  end
end
