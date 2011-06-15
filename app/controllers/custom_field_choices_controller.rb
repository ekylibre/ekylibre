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

class CustomFieldChoicesController < ApplicationController

  def new
    custom_field  = @current_company.custom_fields.find_by_id(params[:id])
    if request.post?
      @custom_field_choice = CustomFieldChoice.new(params[:custom_field_choice])
      @custom_field_choice.company_id = @current_company.id
      # @custom_field_choice.custom_field_id = @custom_field.id
      return if save_and_redirect(@custom_field_choice)
    else
      @custom_field_choice = CustomFieldChoice.new(:custom_field_id=>params[:custom_field_id])
    end
    render_restfully_form
  end

  def create
    custom_field  = @current_company.custom_fields.find_by_id(params[:id])
    if request.post?
      @custom_field_choice = CustomFieldChoice.new(params[:custom_field_choice])
      @custom_field_choice.company_id = @current_company.id
      # @custom_field_choice.custom_field_id = @custom_field.id
      return if save_and_redirect(@custom_field_choice)
    else
      @custom_field_choice = CustomFieldChoice.new(:custom_field_id=>params[:custom_field_id])
    end
    render_restfully_form
  end

  def down
    return unless @custom_field_choice = find_and_check(:custom_field_choice)
    if request.post? and @custom_field_choice
      @custom_field_choice.move_lower
    end
    redirect_to_current
  end

  def up
    return unless @custom_field_choice = find_and_check(:custom_field_choice)
    if request.post? and @custom_field_choice
      @custom_field_choice.move_higher
    end
    redirect_to_current
  end

  def edit
    return unless @custom_field_choice = find_and_check(:custom_field_choice)
    if request.post? and @custom_field_choice
      @custom_field_choice.attributes = params[:custom_field_choice]
      return if save_and_redirect(@custom_field_choice)
    end
    @custom_field = @custom_field_choice.custom_field
    t3e @custom_field_choice.attributes
    render_restfully_form
  end

  def update
    return unless @custom_field_choice = find_and_check(:custom_field_choice)
    if request.post? and @custom_field_choice
      @custom_field_choice.attributes = params[:custom_field_choice]
      return if save_and_redirect(@custom_field_choice)
    end
    @custom_field = @custom_field_choice.custom_field
    t3e @custom_field_choice.attributes
    render_restfully_form
  end

end
