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

class AnimalGroupsController < AdminController
  manage_restfully

  unroll_all

  list do |t|
    t.column :name, :url=>true
    t.column :comment
    t.column :description
    t.action :show, :url=>{:format=>:pdf}, :image=>:print
    t.action :edit
    t.action :destroy, :if=>"RECORD.destroyable\?"
  end

  list(:animals, :conditions=>{:group_id=>['session[:current_animal_group_id]']}, :order=>"name ASC") do |t|
    t.column :name, :url=>true
    t.column :sex
    t.column :working_number, :url=>{:action=>:show}
    t.column :born_on
  end

  list(:events,:model=>:animal_events, :conditions=>{:animal_group_id=>['session[:current_animal_group_id]']}, :order=>"started_on ASC") do |t|
    t.column :name
    t.column :started_on
    t.column :comment
  end

  # Show a list of animals
  def index
  end

  # Show one Animal with params_id
  def show
    return unless @animal_group = find_and_check
    session[:current_animal_group_id] = @animal_group.id
    t3e @animal_group
  end

end
