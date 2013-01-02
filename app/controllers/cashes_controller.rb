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

class CashesController < AdminController

  unroll
  unroll :bank_accounts

  list(:order => :name) do |t|
    t.column :name, :url => true
    t.column :nature
    t.column :currency
    t.column :country
    t.column :number, :through => :account, :url => true
    t.column :name, :through => :journal, :url => true
    t.action :edit
    t.action :destroy
  end

  # Displays the main page with the list of cashes
  def index
  end

  list(:bank_statements, :conditions => {:cash_id => ['session[:current_cash_id]']}, :order => "started_on DESC") do |t|
    t.column :number, :url => true
    t.column :started_on
    t.column :stopped_on
    t.column :credit, :currency => "RECORD.cash.currency"
    t.column :debit, :currency => "RECORD.cash.currency"
  end

  list(:deposits, :conditions => {:cash_id => ['session[:current_cash_id]']}, :order => "created_on DESC") do |t|
    t.column :number, :url => true
    t.column :created_on
    t.column :payments_count
    t.column :amount, :currency => "RECORD.cash.currency"
    t.column :name, :through => :mode
    t.column :comment
  end

  # Displays details of one cash selected with +params[:id]+
  def show
    return unless @cash = find_and_check(:cash)
    session[:current_cash_id] = @cash.id
    t3e @cash.attributes.merge(:nature => @cash.nature)
  end

  def new
    if request.xhr? and params[:mode] == "accountancy"
      @cash = Cash.new(params[:cash])
      render :partial => 'accountancy_form', :locals => {:nature => params[:nature]}
      return
    end
    @cash = Cash.new(:mode => "bban", :currency => Entity.of_company.currency, :nature => "bank_account", :entity_id => params[:entity_id]||Entity.of_company.id)
    render_restfully_form
  end

  def create
    @cash = Cash.new(params[:cash])
    @cash.entity = @cash.entity||Entity.of_company
    return if save_and_redirect(@cash)
    render_restfully_form
  end

  def edit
    return unless @cash = find_and_check(:cash)
    t3e @cash.attributes
    render_restfully_form
  end

  def update
    return unless @cash = find_and_check(:cash)
    @cash.attributes = params[:cash]
    return if save_and_redirect(@cash)
    t3e @cash.attributes
    render_restfully_form
  end

  def destroy
    return unless @cash = find_and_check(:cash)
    @cash.destroy if @cash.destroyable?
    redirect_to :action => :index
  end

end
