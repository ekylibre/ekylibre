# coding: utf-8
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2008-2013 David Joulin, Brice Texier
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

# -*- coding: utf-8 -*-
class Backend::ProductionsController < BackendController
  manage_restfully(:t3e => {:name => :name})

  unroll

  # params:
  #   :q Text search
  #   :s State search
  #   :campaign_id
  #   :product_nature_id
  def self.productions_conditions
    code = ""
    code = search_conditions(:productions => [:state], :activities => [:name], :product_natures => [:name]) + " ||= []\n"
    code << "unless params[:s].blank?\n"
    code << "  unless params[:s] == 'all'\n"
    # code << "    c[0] << \" AND state IN ('draft', 'validated', 'aborted', 'started')\"\n"
    # code << "  else\n"
    code << "    c[0] << \" AND state = ?\"\n"
    code << "    c << params[:s]\n"
    code << "  end\n"
    code << "end\n "
    code << "  if params[:campaign_id].to_i > 0\n"
    code << "    c[0] << \" AND \#{Campaign.table_name}.id = ?\"\n"
    code << "    c << params[:campaign_id].to_i\n"
    code << "  end\n"
    code << "  if params[:product_nature_id].to_i > 0\n"
    code << "    c[0] << \" AND \#{ProductNature.table_name}.id = ?\"\n"
    code << "    c << params[:product_nature_id].to_i\n"
    code << "  end\n"
    code << "c\n "
    return code.c
  end



  list(:conditions => productions_conditions, :joins => [:activity, :product_nature, :campaign]) do |t|
    t.column :name, url: true
    t.column :activity, url: true
    t.column :campaign, url: true
    t.column :product_nature, url: true
    t.column :state_label
    t.action :edit, :if => :draft?
    # t.action :print, :if => :validated?
    t.action :destroy, :if => :aborted?
  end

  # List supports for one production
  list(:supports, :model => :production_supports, :conditions => {production_id: 'params[:id]'.c}, :order => "created_at DESC") do |t|
    t.column :name, through: :storage, url: true
    t.column :net_surface_area, through: :storage
    t.column :created_at
  end

  # List procedures for one production
  list(:interventions, :conditions => {production_id: 'params[:id]'.c}, :order => "created_at DESC") do |t|
    # t.column :name
    t.column :procedure, url: true
    #t.column :name, through: :storage, url: true
    t.column :state
    t.column :incident, url: true
    t.column :started_at
    t.column :stopped_at
    # t.column :provisional
  end

end
