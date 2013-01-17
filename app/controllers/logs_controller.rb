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

class LogsController < AdminController
  manage_restfully

  respond_to :pdf, :html, :xml

  unroll_all

  list do |t|
    t.column :observed_at
  end

  # list do |t|
  #   t.column :name, :url => true
  #   t.column :name, :through => :product, :url => true
  #   t.column :name, :through => :nature, :url => true
  #   t.column :name, :through => :watcher, :url => true
  #   t.column :comment
  #   t.column :description
  #   t.action :show, :url => {:format => :pdf}, :image => :print
  #   t.action :edit
  #   t.action :destroy, :if => :destroyable?
  # end

  # Show a list of @animal_event
  # @TODO FIX Jasperreport gem calling method to work with format pdf
  def index
    @log = Log.all
    respond_to do |format|
     format.json { render json: @log }
     format.xml { render xml: @log , :include  => [:product ] }
     format.pdf { respond_with @log }
     format.html
     end
  end

  # Show one @animal_event with params_id
  def show
    return unless @log = find_and_check
    session[:current_log_id] = @log.id
    t3e @log
  end

end
