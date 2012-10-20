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

class ToolsController < AdminController
  manage_restfully 

  list(:operations, :model=>:operation_uses, :conditions=>{:tool_id=>['session[:current_tool_id]']}, :order=>"created_at ASC") do |t|
    t.column :name,       :through=>:operation, :label=>:column, :url=>true
    t.column :planned_on, :through=>:operation, :label=>:column, :datatype=>:date
    t.column :moved_on,   :through=>:operation, :label=>:column
    t.column :tools_list, :through=>:operation, :label=>:column
    t.column :duration,   :through=>:operation, :label=>:column
  end

  list(:order=>"name") do |t|
    t.column :name, :url=>true
    t.column :text_nature
    t.column :consumption
    t.action :edit
    t.action :destroy, :if=>'RECORD.uses.size == 0'
  end

  # Displays details of one tool selected with +params[:id]+
  def show
    return unless @tool = find_and_check(:tools)
    session[:current_tool_id] = @tool.id
    t3e @tool.attributes
  end

  # Displays the main page with the list of tools
  def index
  end

end
