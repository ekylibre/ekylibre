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

class CustomFieldsController < ApplicationController

  list(:conditions=>{:company_id=>['@current_company.id']}, :order=>:name) do |t|
    t.column :name
    t.column :nature_label
    t.column :required
    t.column :active
    t.column :choices_count, :datatype=>:integer
    t.action :edit
    t.action :custom_field, :image=>:menulist, :if=>'RECORD.nature == "choice"'
  end

  list(:choices, :model=>:custom_field_choices, :conditions=>{:company_id=>['@current_company.id'], :custom_field_id=>['session[:current_custom_field_id]']}, :order=>'position') do |t|
    t.column :name 
    t.column :value
    t.action :up, :if=>"not RECORD.first\?", :method=>:post
    t.action :down, :if=>"not RECORD.last\?", :method=>:post
    t.action :edit
  end



  # Displays details of one custom field selected with +params[:id]+
  def show
    return unless @custom_field = find_and_check(:custom_field)
    session[:current_custom_field_id] = @custom_field.id
    t3e @custom_field.attributes
  end

  def new
    if request.post?
      @custom_field = CustomField.new(params[:custom_field])
      @custom_field.company_id = @current_company.id
      @custom_field.save # Permits to get ID if saved
      return if save_and_redirect(@custom_field, :url=>(@custom_field.nature=='choice' ? {:action=>:custom_field , :id=>@custom_field.id} : :back))
    else
      @custom_field = CustomField.new
    end
    render_restfully_form
  end

  def create
    if request.post?
      @custom_field = CustomField.new(params[:custom_field])
      @custom_field.company_id = @current_company.id
      @custom_field.save # Permits to get ID if saved
      return if save_and_redirect(@custom_field, :url=>(@custom_field.nature=='choice' ? {:action=>:custom_field , :id=>@custom_field.id} : :back))
    else
      @custom_field = CustomField.new
    end
    render_restfully_form
  end

  def sort
    return unless @custom_field = find_and_check(:custom_field)
    if request.post? and @custom_field
      @custom_field.sort_choices
    end
    redirect_to_current
  end

  def edit
    return unless @custom_field = find_and_check(:custom_field)
    if request.post?
      @custom_field.attributes = params[:custom_field]
      return if save_and_redirect(@custom_field)
    end
    t3e @custom_field.attributes
    render_restfully_form
  end

  def update
    return unless @custom_field = find_and_check(:custom_field)
    if request.post?
      @custom_field.attributes = params[:custom_field]
      return if save_and_redirect(@custom_field)
    end
    t3e @custom_field.attributes
    render_restfully_form
  end

  # Displays the main page with the list of custom fields
  def index
  end

end
