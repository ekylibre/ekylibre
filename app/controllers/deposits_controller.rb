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

class DepositsController < ApplicationController

  list(:conditions=>{:company_id=>['@current_company.id']}, :order=>"created_at DESC") do |t|
    t.column :number, :url=>true
    t.column :amount, :url=>true
    t.column :payments_count
    t.column :name, :through=>:cash, :url=>true
    t.column :label, :through=>:responsible
    t.column :created_on
    t.action :show, :url=>{:format=>:pdf}, :image=>:print
    t.action :edit, :if=>'RECORD.locked == false'
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>'RECORD.locked == false'
  end

  # Displays the main page with the list of deposits
  def index
    notify_now(:no_depositable_payments) if @current_company.depositable_payments.size <= 0
  end


  list(:payments, :model=>:incoming_payments, :conditions=>{:company_id=>['@current_company.id'], :deposit_id=>['session[:deposit_id]']}, :per_page=>1000, :order=>:number) do |t|
    t.column :number, :url=>true
    t.column :full_name, :through=>:payer, :url=>true
    t.column :bank
    t.column :account_number
    t.column :check_number
    t.column :paid_on
    t.column :amount, :url=>true
  end

  # Displays details of one deposit selected with +params[:id]+
  def show
    return unless @deposit = find_and_check(:deposit)
    respond_to do |format|
      format.html do
        session[:deposit_id] = @deposit.id
        t3e @deposit.attributes
      end
      format.pdf { render_print_deposit(@deposit) }
    end
  end


  list(:depositable_payments, :model=>:incoming_payments, :conditions=>["#{IncomingPayment.table_name}.company_id=? AND (deposit_id=? OR (mode_id=? AND deposit_id IS NULL))", ['@current_company.id'], ['session[:deposit_id]'], ['session[:payment_mode_id]']], :pagination=>:none, :order=>"to_bank_on, created_at", :line_class=>"((RECORD.to_bank_on||Date.yesterday)>Date.today ? 'critic' : '')") do |t|
    t.column :number, :url=>true
    t.column :full_name, :through=>:payer, :url=>true
    t.column :bank
    t.column :account_number
    t.column :check_number
    t.column :paid_on
    t.column :label, :through=>:responsible
    t.column :amount
    t.check_box :to_deposit, :value=>'(RECORD.to_bank_on<=Date.today and (session[:deposit_id].nil? ? (RECORD.responsible.nil? or RECORD.responsible_id==@current_user.id) : (RECORD.deposit_id==session[:deposit_id])))', :label=>tc(:to_deposit)
  end

  def new
    return unless mode = find_mode
    session[:deposit_id] = nil
    session[:payment_mode_id] = mode.id
    @deposit = Deposit.new(:created_on=>Date.today, :mode_id=>mode.id, :responsible_id=>@current_user.id)
    t3e :mode=>mode.name
    render_restfully_form
  end

  def create
    return unless mode = find_mode
    session[:deposit_id] = nil
    session[:payment_mode_id] = mode.id
    @deposit = Deposit.new(params[:deposit])
    @deposit.mode_id = mode.id 
    @deposit.company_id = @current_company.id 
    if @deposit.save
      payments = params[:depositable_payments].collect{|id, attrs| (attrs[:to_deposit].to_i==1 ? id.to_i : nil)}.compact
      IncomingPayment.update_all({:deposit_id=>@deposit.id}, ["company_id=? AND id IN (?)", @current_company.id, payments])
      @deposit.refresh
      return if save_and_redirect(@deposit, :saved=>true)
    end
    t3e :mode=>mode.name
    render_restfully_form
  end

  def edit
    return unless @deposit = find_and_check(:deposit)
    session[:deposit_id] = @deposit.id
    session[:payment_mode_id] = @deposit.mode_id
    t3e @deposit.attributes
    render_restfully_form
  end

  def update
    return unless @deposit = find_and_check(:deposit)
    session[:deposit_id] = @deposit.id
    session[:payment_mode_id] = @deposit.mode_id
    if @deposit.update_attributes(params[:deposit])
      ActiveRecord::Base.transaction do
        payments = params[:depositable_payments].collect{|id, attrs| (attrs[:to_deposit].to_i==1 ? id.to_i : nil)}.compact
        IncomingPayment.update_all({:deposit_id=>nil}, ["company_id=? AND deposit_id=?", @current_company.id, @deposit.id])
        IncomingPayment.update_all({:deposit_id=>@deposit.id}, ["company_id=? AND id IN (?)", @current_company.id, payments])
      end
      @deposit.refresh
      return if save_and_redirect(@deposit, :saved=>true)
    end
    t3e @deposit.attributes
    render_restfully_form
  end

  def destroy
    return unless @deposit = find_and_check(:deposit)
    @deposit.destroy if @deposit.destroyable?
    redirect_to_current
  end


  list(:unvalidateds, :model=>:deposits, :conditions=>{:locked=>false, :company_id=>['@current_company.id']}) do |t|
    t.column :created_on
    t.column :amount
    t.column :payments_count
    t.column :name, :through=>:cash, :url=>true
    t.check_box :validated, :value=>'RECORD.created_on<=Date.today-(15)'
  end

  def unvalidateds
    @deposits = @current_company.deposits_to_lock
    if request.post?
      for id, values in params[:unvalidated_deposits]
        return unless deposit = find_and_check(:deposit, id)
        deposit.update_attributes!(:locked=>true) if deposit and values[:validated].to_i == 1
      end
      redirect_to :action=>:unvalidateds
    end
  end

  protected

  def find_mode()
    mode = @current_company.incoming_payment_modes.find_by_id(params[:mode_id])
    if mode.nil?
      notify_warning(:need_payment_mode_to_create_deposit)
      redirect_to :action=>:index
      return nil
    end
    if mode.depositable_payments.size <= 0
      notify_warning(:no_payment_to_deposit)
      redirect_to :action=>:index
      return nil
    end
    return mode
  end

end
