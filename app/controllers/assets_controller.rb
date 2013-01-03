# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2008-2012 Brice Texier
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

class AssetsController < AdminController
  manage_restfully :currency=>'Entity.of_company.currency', :depreciation_method=>"'linear'"

  unroll_all

  list do |t|
    t.column :number, :url=>true
    t.column :name, :url=>true
    t.column :depreciable_amount, :currency => true
    t.column :started_on
    t.column :stopped_on
    t.action :edit
    t.action :destroy
  end

  def index
  end

  list(:depreciations, :model => :asset_depreciations, :conditions => {:asset_id => ['params[:id]']}, :order => :position) do |t|
    t.column :amount, :currency => true
    t.column :asset_amount, :currency => true
    t.column :depreciated_amount, :currency => true
    t.column :started_on
    t.column :stopped_on
    t.column :code, :through => :financial_year, :url => true
    t.column :number, :through => :journal_entry, :url => true
    t.action :edit, :if => "RECORD.journal_entry.nil? "
  end

  # Displays details of an asset
  def show
    return unless @asset = find_and_check
    t3e @asset.attributes
  end

  # def cede
  #   return unless @asset = find_and_check
  # end

  # def sell
  #   return unless @asset = find_and_check
  # end

  # def depreciate
  #   return unless @asset = find_and_check
  #   @asset.depreciate!
  #   redirect_to asset_url(@asset)
  # end

end
