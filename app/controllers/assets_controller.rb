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

class AssetsController < ApplicationController
  manage_restfully :currency=>'@current_company.default_currency', :depreciation_method=>"'linear'"

  list(:conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name, :url=>true
    t.column :purchase_amount
    t.column :depreciable_amount
    t.column :current_amount, :type=>:numeric
    t.column :started_on
    t.column :stopped_on
    t.action :edit
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  def index
  end

  # Displays details of an asset
  def show
    return unless @asset = find_and_check(:attribute)
    t3e @asset.attributes
  end

end
