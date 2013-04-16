# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2012-2013 David Joulin, Brice Texier
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

class Backend::MattersController < BackendController
  manage_restfully :t3e => {:nature_name => "@matter.nature_name"}

  respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

  unroll_all

  list do |t|
    t.column :work_number, :url => true
    t.column :name, :url => true
    t.column :born_at
    t.action :show, :url => {:format => :pdf}, :image => :print
    t.action :edit
    t.action :destroy, :if => :destroyable?
  end

  # Show a list of matter

  def index
    @matter = Matter.all
    #parsing a parameter to Jasper for company full name
    @entity_full_name = Entity.of_company.full_name
    #respond with associated models to simplify quering in Ireport
    respond_with @matter, :include => [:variety, :nature]
  end

  # Liste des lieux de la matière considérée
  list(:place, :model => :product_localizations, :conditions => [" product_id = ? ",['session[:current_matter_id]']], :order => "started_at DESC") do |t|
    t.column :name, :through => :container, :url => true
    t.column :nature
    t.column :started_at
    t.column :arrival_cause
    t.column :stopped_at
    t.column :departure_cause
  end

  # Liste des groupes de la matière considérée
  list(:group, :model => :product_memberships, :conditions => [" member_id = ? ",['session[:current_matter_id]']], :order => "started_at DESC") do |t|
    t.column :name, :through =>:group, :url => true
    t.column :started_at
    t.column :stopped_at
  end

  # Show one matter with params_id
  def show
    return unless @matter = find_and_check
        session[:current_matter_id] = @matter.id
        t3e @matter, :nature_name => @matter.nature_name
        respond_with(@matter, :include => [:father, :mother, :nature, :variety,
                                                   {:indicator_data => {:include => :indicator}},
                                                   {:memberships => {:include =>:group}},
                                                    {:product_localizations => {:include =>:container}}])
  end

  def picture
    return unless @matter = find_and_check
    send_file @matter.picture.path(params[:style] || :original)
  end

end
