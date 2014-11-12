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

class Backend::IncomingPaymentModesController < BackendController
  manage_restfully with_accounting: true
  manage_restfully_list :name

  unroll

  list(order: :position) do |t|
    t.column :name
    t.column :cash, url: true
    t.column :with_accounting
    t.column :with_deposit
    t.column :detail_payments, hidden: true
    t.column :depositables_account, url: true, hidden: true
    t.column :depositables_journal, url: true, hidden: true
    t.column :with_commission
    t.action :up,   method: :post, :unless => :first?
    t.action :down, method: :post, :unless => :last?
    t.action :reflect, method: :post, confirm: true
    t.action :edit
    t.action :destroy, if: :destroyable?
  end

  def reflect
    return unless @incoming_payment_mode = find_and_check
    @incoming_payment_mode.reflect
    redirect_to action: :index
  end

end
