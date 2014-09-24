# -*- coding: utf-8 -*-
# == License
# Ekylibre ERP - Simple agricultural ERP
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

class Backend::CashesController < BackendController
  manage_restfully mode: 'Cash.mode.default_value'.c, currency: 'Preference[:currency]'.c, nature: 'Cash.nature.default_value'.c, t3e: {nature: 'RECORD.nature.text'.c}

  unroll

  list(order: :name) do |t|
    t.column :name, url: true
    t.column :nature
    t.column :currency
    t.column :country
    t.column :account, url: true
    t.column :journal, url: true
    t.action :edit
    t.action :destroy
  end

  list(:bank_statements, conditions: {cash_id: 'params[:id]'.c}, order: {started_at: :desc}) do |t|
    t.column :number, url: true
    t.column :started_at
    t.column :stopped_at
    t.column :credit, currency: true
    t.column :debit, currency: true
  end

  list(:deposits, conditions: {cash_id: 'params[:id]'.c}, order: {created_at: :desc}) do |t|
    t.column :number, url: true
    t.column :created_at
    t.column :payments_count
    t.column :amount, currency: true
    t.column :mode
    t.column :description
  end

end
