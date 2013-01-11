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

class IncomingPaymentUsesController < AdminController

  def new
    expense = nil
    return unless expense = find_and_check(params[:expense_type], params[:expense_id])
    @incoming_payment_use = IncomingPaymentUse.new(:expense_id => expense.id, :expense_type => expense.class.name, :downpayment => !expense.invoice?)
    # t3e :type => expense.class.model_name.human, :number => expense.number, :label => expense.label
    render_restfully_form
  end

  def create
    expense = nil
    @incoming_payment_use = IncomingPaymentUse.new(params[:incoming_payment_use])
    return if save_and_redirect(@incoming_payment_use)
    expense = @incoming_payment_use.expense
    t3e :type => expense.class.model_name.human, :number => expense.number, :label => expense.label
    render_restfully_form
  end

  def destroy
    return unless @incoming_payment_use = find_and_check(:incoming_payment_use)
    @incoming_payment_use.destroy
    redirect_to_back
  end

end
