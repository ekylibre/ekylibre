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

class Backend::DepositsController < BackendController

  unroll

  list(order: {created_at: :desc}) do |t|
    t.column :number, url: true
    t.column :amount, currency: true, url: true
    t.column :payments_count
    t.column :cash, url: true
    t.column :responsible
    t.column :created_on
    t.column :description
    t.action :show, url: {:format => :pdf}, image: :print
    t.action :edit, :unless => :locked?
    t.action :destroy, :unless => :locked?
  end

  # Displays the main page with the list of deposits
  def index
    notify_now(:no_depositable_payments) if IncomingPayment.depositables.count.zero?
  end


  list(:payments, model: :incoming_payments, conditions: {deposit_id: 'params[:id]'.c}, :pagination => :none, order: :number) do |t|
    t.column :number, url: true
    t.column :payer, url: true
    t.column :bank_name
    t.column :bank_account_number
    t.column :bank_check_number
    t.column :paid_on
    t.column :amount, currency: true, url: true
  end

  # Displays details of one deposit selected with +params[:id]+
  def show
    return unless @deposit = find_and_check(:deposit)
    respond_to do |format|
      format.html do
        t3e @deposit.attributes
      end
      format.pdf { render_print_deposit(@deposit) }
    end
  end


  list(:depositable_payments, model: :incoming_payments, conditions: ["deposit_id=? OR (mode_id=? AND deposit_id IS NULL)", 'session[:deposit_id]'.c, 'session[:payment_mode_id]'.c], :pagination => :none, order: [:to_bank_on, :created_at], :line_class => "((RECORD.to_bank_on||Date.yesterday)>Date.today ? 'critic' : '')".c) do |t|
    t.column :number, url: true
    t.column :payer, url: true
    t.column :bank_name
    t.column :bank_account_number
    t.column :bank_check_number
    t.column :paid_on
    t.column :responsible
    t.column :amount, currency: true
    t.check_box :to_deposit, :value => '(RECORD.to_bank_on<=Date.today and (session[:deposit_id].nil? ? (RECORD.responsible.nil? or RECORD.responsible_id==current_user.person_id) : (RECORD.deposit_id==session[:deposit_id])))'.c, :label => tc(:to_deposit)
  end

  def new
    return unless mode = find_mode
    session[:deposit_id] = nil
    session[:payment_mode_id] = mode.id
    @deposit = Deposit.new(:created_on => Date.today, :mode_id => mode.id, :responsible => current_user.person)
    t3e :mode => mode.name
    # render_restfully_form
  end

  def create
    return unless mode = find_mode
    session[:deposit_id] = nil
    session[:payment_mode_id] = mode.id
    @deposit = Deposit.new(permitted_params)
    @deposit.mode_id = mode.id
    if @deposit.save
      payments = params[:depositable_payments].collect{|id, attrs| (attrs[:to_deposit].to_i==1 ? id.to_i : nil)}.compact
      IncomingPayment.where(:id => payments).update_all(:deposit_id => @deposit.id)
      @deposit.refresh
      return if save_and_redirect(@deposit, :saved => true)
    end
    t3e :mode => mode.name
    # render_restfully_form
  end

  def edit
    return unless @deposit = find_and_check(:deposit)
    session[:deposit_id] = @deposit.id
    session[:payment_mode_id] = @deposit.mode_id
    t3e @deposit.attributes
    # render_restfully_form
  end

  def update
    return unless @deposit = find_and_check(:deposit)
    session[:deposit_id] = @deposit.id
    session[:payment_mode_id] = @deposit.mode_id
    if @deposit.update_attributes(permitted_params) and params[:depositable_payments]
      ActiveRecord::Base.transaction do
        payments = params[:depositable_payments].collect{|id, attrs| (attrs[:to_deposit].to_i==1 ? id.to_i : nil)}.compact
        IncomingPayment.where(:deposit_id => @deposit.id).update_all(:deposit_id => nil)
        IncomingPayment.where(:id => payments).update_all(:deposit_id => @deposit.id)
      end
      @deposit.refresh
      return if save_and_redirect(@deposit, :saved => true)
    end
    t3e @deposit.attributes
    # render_restfully_form
  end

  def destroy
    return unless @deposit = find_and_check(:deposit)
    @deposit.destroy if @deposit.destroyable?
    redirect_to_current
  end


  list(:unvalidateds, model: :deposits, conditions: {:locked => false}) do |t|
    t.column :created_on
    t.column :amount
    t.column :payments_count
    t.column :cash, url: true
    t.check_box :validated, :value => 'RECORD.created_on<=Date.today-(15)'.c
  end

  def unvalidateds
    @deposits = Deposit.unvalidateds
    if request.post?
      for id, values in params[:unvalidateds] || {}
        return unless deposit = find_and_check(:deposit, id)
        deposit.update_attributes!(:locked => true) if deposit and values[:validated].to_i == 1
      end
      redirect_to :action => :unvalidateds
    end
  end

  protected

  def find_mode()
    mode = IncomingPaymentMode.find_by_id(params[:mode_id])
    if mode.nil?
      notify_warning(:need_payment_mode_to_create_deposit)
      redirect_to :action => :index
      return nil
    end
    if mode.depositable_payments.size <= 0
      notify_warning(:no_payment_to_deposit)
      redirect_to :action => :index
      return nil
    end
    return mode
  end

  def permitted_params
    params.permit!(:deposit)
  end

end
