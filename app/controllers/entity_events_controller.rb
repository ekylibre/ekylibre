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

class EntityEventsController < AdminController
  manage_restfully :responsible_id=>'current_user.id', :entity_id=>"Entity.find(params[:entity_id]).id rescue 0", :nature_id=>"EntityEventNature.first.id rescue nil", :duration=>"EntityEventNature.first.duration rescue 0", :started_at=>"Time.now.to_s(:db)"

  unroll_all

  list(:conditions=>search_conditions(:entity_events, :entity_events=>[:duration, :location, :reason, :started_at], :users=>[:first_name, :last_name, :name], :entities=>[:full_name], :entity_event_natures=>[:name]), :order=>"started_at DESC") do |t| # , :joins=>{:responsible=>{}, :entity=>[:nature]}
    t.column :full_name, :through=>:entity, :url=>true
    t.column :duration
    t.column :location
    t.column :label, :through=>:responsible, :url=>true
    t.column :name, :through=>:nature
    t.column :started_at
    t.action :edit
    t.action :destroy
  end

  # Displays the main page with the list of events
  def index
    session[:entity_event_key] = params[:q] # = params[:q]||session[:event_key]
  end

  def change_minutes
    return unless @entity_event_nature = find_and_check(:entity_event_nature, params[:nature_id])
    value = @entity_event_nature.send(params[:field] || :name)
    render :text=>value.to_s, :layout=>false
  end

end
