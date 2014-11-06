# -*- coding: utf-8 -*-
# == License
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class Backend::CashTransfersController < BackendController
  manage_restfully transfered_at: 'Date.today'.c

  unroll

  list do |t|
    t.column :number,           url: true
    t.column :emission_amount,             currency: :emission_currency
    t.column :emission_cash,    url: true
    t.column :reception_amount,            currency: :reception_currency
    t.column :reception_cash,   url: true
    t.column :transfered_at
    t.column :description
    t.action :edit
    t.action :destroy
  end

end
