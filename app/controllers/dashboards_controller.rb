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

class DashboardsController < AdminController

  list(:my_future_events, :model=>:events, :conditions=>['started_at >= CURRENT_TIMESTAMP'], :order=>"started_at ASC", :line_class=>"(RECORD.responsible_id=@current_user.id ? 'notice' : '')", :per_page=>10) do |t|
    t.column :started_at
    t.column :full_name, :through=>:entity, :url=>true
    t.column :name, :through=>:nature
    t.column :duration
    t.column :location
    t.column :label, :through=>:responsible, :url=>true
  end

  list(:recent_events, :model=>:events, :conditions=>['started_at < CURRENT_TIMESTAMP'], :order=>"started_at DESC", :per_page=>10) do |t|
    t.column :started_at
    t.column :full_name, :through=>:entity, :url=>true
    t.column :name, :through=>:nature
    t.column :duration
    t.column :location
    t.column :label, :through=>:responsible, :url=>true
  end

  list(:critic_stocks, :model=>:stocks, :conditions=>['#{Stock.table_name}.virtual_quantity <= #{Stock.table_name}.quantity_min AND NOT (#{Stock.table_name}.virtual_quantity=0 AND #{Stock.table_name}.quantity=0 AND #{Stock.table_name}.tracking_id IS NOT NULL)'] , :line_class=>'RECORD.state', :order=>'virtual_quantity/(2*quantity_min+0.01)') do |t|
    t.column :name, :through=>:product, :url=>true
    t.column :name, :through=>:warehouse, :url=>true
    t.column :name, :through=>:tracking, :url=>true
    t.column :critic_quantity_min
    t.column :quantity_min
    t.column :quantity_max
    t.column :virtual_quantity
    t.column :quantity
    t.column :name, :through=>:unit
  end


  for menu in Ekylibre.menu.with_menus do
    h = menu.hierarchy.collect{|m| m.name }[1..-1]
    next if h.empty?
    code  = "def " + h.join("_") + "\n"
    code << "  render :file => 'dashboards/" + h.join("/") + "', :layout => dialog_or_not\n"
    code << "end\n"
    class_eval code
  end

  def index
  end

  def welcome
    redirect_to :action => :index
  end

end
