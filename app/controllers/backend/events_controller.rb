# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class Backend::EventsController < BackendController
  manage_restfully :nature_id => "EventNature.first.id rescue nil".c, :started_at => "Time.now".c

  unroll

  autocomplete_for :place

  list(:conditions => search_conditions(:events => [:duration, :place, :name, :description, :started_at], :event_natures => [:name]), :order => "started_at DESC") do |t|
    t.column :name
    t.column :casting
    t.column :duration
    t.column :place
    t.column :name, through: :nature
    t.column :started_at
    t.action :edit
    t.action :destroy
  end

  def change_minutes
    return unless nature = find_and_check(:event_nature, params[:nature_id])
    value = nature.send(params[:field] || :name)
    render :text => value.to_s, :layout => false
  end

  list(:participations, model: :event_participations, conditions: {event_id: 'params[:id]'.c}, order: :id) do |t|
    t.column :name, through: :participant
    t.column :state
    t.action :destroy
  end
end
