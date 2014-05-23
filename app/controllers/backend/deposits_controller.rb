# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple agricultural ERP
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

class Backend::DepositsController < BackendController
  manage_restfully only: :destroy

  unroll

  list(order: {created_at: :desc}) do |t|
    t.column :number, url: true
    t.column :amount, currency: true, url: true
    t.column :payments_count
    t.column :cash, url: true
    t.column :responsible, url: true
    t.column :created_at
    t.column :description, hidden: true
    t.column :journal_entry, url: true
    # t.action :show, url: {format: :pdf}, image: :print
    t.action :edit, :unless => :locked?
    t.action :destroy, :unless => :locked?
  end

  # Displays the main page with the list of deposits
  def index
    unless IncomingPayment.depositables.any?
      notify_now(:no_depositable_payments)
    end
  end


  list(:payments, model: :incoming_payments, conditions: {deposit_id: 'params[:id]'.c}, :pagination => :none, order: :number) do |t|
    t.column :number, url: true
    t.column :payer, url: true
    t.column :bank_name
    t.column :bank_account_number
    t.column :bank_check_number
    t.column :paid_at
    t.column :amount, currency: true, url: true
  end

  # Displays details of one deposit selected with +params[:id]+
  def show
    return unless @deposit = find_and_check
    respond_to do |format|
      format.html do
        t3e @deposit.attributes
      end
      format.pdf { render_print_deposit(@deposit) }
    end
  end


  list(:depositable_payments, model: :incoming_payments, conditions: ["deposit_id=? OR (mode_id=? AND deposit_id IS NULL)", 'params[:id]'.c, '(resource.mode_id rescue params[:mode_id])'.c], paginate: false, order: [:to_bank_at, :created_at], :line_class => "((resource.payments.exists?(RECORD) rescue false) ? 'success' : (RECORD.to_bank_at||Date.yesterday) > Date.today ? 'critic' : '')".c) do |t|
    t.column :number, url: true
    t.column :payer, url: true
    t.column :bank_name
    t.column :bank_account_number
    t.column :bank_check_number
    t.column :paid_at
    t.column :responsible
    t.column :amount, currency: true
    t.check_box :to_deposit, value: '(resource.payments.exists?(RECORD) rescue false) || (RECORD.to_bank_at<=Date.today and (params[:id].blank? ? (RECORD.responsible.nil? or RECORD.responsible_id == current_user.person_id) : (RECORD.deposit_id == params[:id])))'.c, label: tc(:to_deposit), form_name: "deposit[payment_ids][]", form_value: "RECORD.id".c
  end

  def new
    return unless mode = find_mode
    @deposit = Deposit.new(created_at: Date.today, mode: mode, responsible: current_user.person)
    t3e mode: @deposit.mode.name
  end

  def create
    return unless find_mode
    @deposit = Deposit.new(permitted_params)
    return if save_and_redirect(@deposit)
    t3e mode: @deposit.mode.name
  end

  def edit
    return unless @deposit = find_and_check
    t3e @deposit
  end

  def update
    return unless @deposit = find_and_check
    return if save_and_redirect(@deposit, attributes: permitted_params, url: {action: :index})
    #  @deposit.update_attributes(permitted_params) and params[:depositable_payments]
    #   ActiveRecord::Base.transaction do
    #     payments = params[:depositable_payments].collect{|id, attrs| (attrs[:to_deposit].to_i==1 ? id.to_i : nil)}.compact
    #     IncomingPayment.where(:deposit_id => @deposit.id).update_all(:deposit_id => nil)
    #     IncomingPayment.where(id: payments).update_all(:deposit_id => @deposit.id)
    #   end
    #   @deposit.refresh
    #   return if save_and_redirect(@deposit, :saved => true)
    # end
    t3e @deposit
  end

  list(:unvalidateds, model: :deposits, conditions: {:locked => false}) do |t|
    t.column :created_at
    t.column :amount
    t.column :payments_count
    t.column :cash, url: true
    t.check_box :validated, :value => 'RECORD.created_at<=Date.today-(15)'.c
  end

  def unvalidateds
    @deposits = Deposit.unvalidateds
    if request.post?
      for id, values in params[:unvalidateds] || {}
        return unless deposit = find_and_check(id: id)
        deposit.update_attributes!(:locked => true) if deposit and values[:validated].to_i == 1
      end
      redirect_to action: :unvalidateds
    end
  end

  protected

  def find_mode(id = nil)
    unless mode = IncomingPaymentMode.find_by(id: id || params[:mode_id])
      notify_warning(:need_payment_mode_to_create_deposit)
      redirect_to action: :index
      return nil
    end
    if params[:deposit] and params[:deposit][:mode_id] and params[:deposit][:mode_id].to_i != mode.id
      notify_error(:need_payment_mode_to_create_deposit)
      redirect_to action: :index
      return nil
    end
    unless mode.depositable_payments.any?
      notify_warning(:no_payment_to_deposit)
      redirect_to action: :index
      return nil
    end
    return mode
  end

end
