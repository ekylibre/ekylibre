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

class OutgoingPaymentModesController < ApplicationController
  manage_restfully :with_accounting=>"true"
  manage_restfully_list :name

  list(:conditions=>{:company_id=>['@current_company.id']}, :order=>:position) do |t|
    t.column :name
    t.column :with_accounting
    t.column :name, :through=>:cash, :url=>true
    t.action :up, :method=>:post, :if=>"!RECORD.first\?"
    t.action :down, :method=>:post, :if=>"!RECORD.last\?"
    t.action :edit
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.destroyable\?"
  end

  # Displays the main page with the list of outgoing payment modes
  def index
  end

end
