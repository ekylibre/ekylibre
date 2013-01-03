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

class IncomingPaymentModesController < AdminController
  manage_restfully :with_accounting => "true"
  manage_restfully_list :name

  unroll_all

  # TODO: Adds detail_payments and attorney_journal
  list(:order => :position) do |t|
    t.column :name
    t.column :name, :through => :cash, :url => true
    t.column :with_accounting
    t.column :with_deposit
    t.column :label, :through => :depositables_account, :url => true
    t.column :name,  :through => :depositables_journal, :url => true
    t.column :with_commission
    t.action :up,   :method => :post, :unless => :first?
    t.action :down, :method => :post, :unless => :last?
    t.action :reflect, :method => :post, 'data-confirm' => :are_you_sure
    t.action :edit
    t.action :destroy, :if => :destroyable?
  end

  def reflect
    return unless @incoming_payment_mode = find_and_check
    for payment in @incoming_payment_mode.unlocked_payments
      payment.update_attributes(:commission_account_id => nil, :commission_amount => nil)
    end
    redirect_to :action => :index
  end

  # Displays the main page with the list of incoming payment modes
  def index
  end

end
