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

class OutgoingPaymentUsesController < ApplicationController

  def new
    expense = nil
    if request.post?
      @outgoing_payment_use = OutgoingPaymentUse.new(params[:outgoing_payment_use])
      if @outgoing_payment_use.save
        redirect_to_back
      end
      expense = @outgoing_payment_use.expense
#       unless outgoing_payment = @current_company.outgoing_payments.find_by_id(params[:outgoing_payment_use][:payment_id])
#         @outgoing_payment_use.errors.add(:payment_id, :required)
#         return
#       end
#       if outgoing_payment.pay(expense, :downpayment=>params[:outgoing_payment_use][:downpayment])
#         redirect_to_back
#       end
    else
      return unless expense = find_and_check(:purchase, params[:expense_id])
      @outgoing_payment_use = OutgoingPaymentUse.new(:expense=>expense)
    end
    t3e :number=>expense.number
    render_restfully_form
  end

  def create
    expense = nil
    if request.post?
      @outgoing_payment_use = OutgoingPaymentUse.new(params[:outgoing_payment_use])
      if @outgoing_payment_use.save
        redirect_to_back
      end
      expense = @outgoing_payment_use.expense
#       unless outgoing_payment = @current_company.outgoing_payments.find_by_id(params[:outgoing_payment_use][:payment_id])
#         @outgoing_payment_use.errors.add(:payment_id, :required)
#         return
#       end
#       if outgoing_payment.pay(expense, :downpayment=>params[:outgoing_payment_use][:downpayment])
#         redirect_to_back
#       end
    else
      return unless expense = find_and_check(:purchase, params[:expense_id])
      @outgoing_payment_use = OutgoingPaymentUse.new(:expense=>expense)
    end
    t3e :number=>expense.number
    render_restfully_form
  end

  def destroy
    return unless @outgoing_payment_use = find_and_check(:outgoing_payment_use)
    if request.post? or request.delete?
      @outgoing_payment_use.destroy #:action=>:purchase_summary, :id=>@purchase.id
    end
    redirect_to_back
  end

end
