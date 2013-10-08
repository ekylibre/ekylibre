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

class Backend::FinancialYearsController < BackendController
  manage_restfully

  unroll

  list(:order => "started_on DESC") do |t|
    t.column :code, url: true
    t.column :closed
    t.column :started_on, url: true
    t.column :stopped_on, url: true
    t.column :currency
    # t.column :currency_precision
    # t.action :close, :if => '!RECORD.closed and RECORD.closable?'
    t.action :edit, :unless => :closed?
    t.action :destroy, :unless => :closed?
  end

  list(:account_balances, :joins => :account, :conditions => {:financial_year_id => 'params[:id]'.c}, :order => "number") do |t|
    t.column :account, url: true
    t.column :account_number, through: :account, label_method: :number, url: true, hidden: true
    t.column :account_name, through: :account, label_method: :name, url: true, hidden: true
    t.column :local_debit, currency: true
    t.column :local_credit, currency: true
  end

  list(:asset_depreciations, :conditions => {:financial_year_id => 'params[:id]'.c}) do |t|
    t.column :asset, url: true
    t.column :started_on
    t.column :stopped_on
    t.column :amount, currency: true
  end

  # Displays details of one financial year selected with +params[:id]+
  def show
    return unless @financial_year = find_and_check
    respond_to do |format|
      format.html do
        if @financial_year.closed? and @financial_year.account_balances.size.zero?
          @financial_year.compute_balances!
        end
        t3e @financial_year.attributes
      end
      format.pdf do
        if params[:n] == "balance_sheet"
          render_print_balance_sheet(@financial_year)
        else
          render_print_income_statement(@financial_year)
        end
      end
    end
  end

  def compute_balances
    return unless @financial_year = find_and_check
    @financial_year.compute_balances!
    redirect_to_current
  end


  def close
    # Launch close process
    return unless @financial_year = find_and_check
    if request.post?
      params[:journal_id] = Journal.create!(:nature => "renew").id if params[:journal_id]=="0"
      if @financial_year.close(params[:financial_year][:stopped_on].to_date, :renew_id => params[:journal_id])
        notify_success(:closed_financial_years)
        redirect_to(:action => :index)
      end
    else
      journal = Journal.used_for(:forward).first
      params[:journal_id] = (journal ? journal.id : 0)
    end
    t3e @financial_year.attributes
  end

  def new
    @financial_year = FinancialYear.new
    f = FinancialYear.last
    @financial_year.started_on = f.stopped_on+1.day unless f.nil?
    @financial_year.started_on ||= Date.today
    @financial_year.stopped_on = (@financial_year.started_on+1.year-1.day).end_of_month
    @financial_year.code = @financial_year.default_code
    @financial_year.currency = @financial_year.previous.currency if @financial_year.previous
    @financial_year.currency ||= Entity.of_company.currency
    # render_restfully_form
  end

  def create
    @financial_year = FinancialYear.new(params[:financial_year])
    return if save_and_redirect(@financial_year)
    # render_restfully_form
  end

  def edit
    return unless @financial_year = find_and_check
    t3e @financial_year.attributes
    # render_restfully_form
  end

  def update
    return unless @financial_year = find_and_check
    @financial_year.attributes = params[:financial_year]
    return if save_and_redirect(@financial_year)
    t3e @financial_year.attributes
    # render_restfully_form
  end

  def destroy
    return unless @financial_year = find_and_check
    @financial_year.destroy if @financial_year.destroyable?
    redirect_to :action => :index
  end

  def generate_last_journal_entry
    return unless @financial_year = find_and_check
    if request.get?
      params[:assets_depreciations] ||= 1
    elsif request.post?
      # TODO: Defines journal to save the entry
      @financial_year.generate_last_journal_entry(params)
      redirect_to journal_entry_url(@financial_year.last_journal_entry)
    end
    t3e @financial_year.attributes
  end

end
