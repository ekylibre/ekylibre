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

class CustomFieldsController < AdminController
  manage_restfully :redirect_to=>'(@custom_field.nature=="choice" ? {:action=>:show, :id=>"id"} : :back)'
  manage_restfully_list

  list(:order=>:position) do |t|
    t.column :name, :url=>true
    t.column :nature_label
    t.column :required
    t.column :active
    t.column :choices_count, :datatype=>:integer
    t.action :up, :method=>:post, :if=>'!RECORD.first? '
    t.action :down, :method=>:post, :if=>'!RECORD.last? '
    t.action :edit
    t.action :show, :image=>:menulist, :if=>"(RECORD.nature == 'choice')"
  end

  # Displays the main page with the list of custom fields
  def index
  end

  list(:choices, :model=>:custom_field_choices, :conditions=>{:custom_field_id=>['session[:current_custom_field_id]']}, :order=>'position') do |t|
    t.column :name
    t.column :value
    t.action :up, :if=>"not RECORD.first\?", :method=>:post
    t.action :down, :if=>"not RECORD.last\?", :method=>:post
    t.action :edit
    t.action :destroy, :if=>"RECORD.destroyable\?"
  end

  # Displays details of one custom field selected with +params[:id]+
  def show
    return unless @custom_field = find_and_check(:custom_field)
    session[:current_custom_field_id] = @custom_field.id
    t3e @custom_field.attributes
  end

  # Sort all choices by name
  def sort
    return unless @custom_field = find_and_check(:custom_field)
    @custom_field.sort_choices
    redirect_to_current
  end

end
