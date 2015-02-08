# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple agricultural ERP
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

class Backend::FinancialYearsController < Backend::BaseController
  manage_restfully except: [:new, :show]

  unroll

  list(order: {started_on: :desc}) do |t|
    t.column :code, url: true
    t.column :closed
    t.column :started_on, url: true
    t.column :stopped_on, url: true
    t.column :currency
    # t.column :currency_precision
    # t.action :close, if: '!RECORD.closed and RECORD.closable?'
    t.action :edit, unless: :closed?
    t.action :destroy, unless: :closed?
  end

  list(:account_balances, joins: :account, conditions: {financial_year_id: 'params[:id]'.c}, order: "accounts.number") do |t|
    t.column :account, url: true
    t.column :account_number, through: :account, label_method: :number, url: true, hidden: true
    t.column :account_name,   through: :account, label_method: :name, url: true, hidden: true
    t.column :local_debit,  currency: true
    t.column :local_credit, currency: true
  end

  list(:financial_asset_depreciations, conditions: {financial_year_id: 'params[:id]'.c}) do |t|
    t.column :financial_asset, url: true
    t.column :started_on
    t.column :stopped_on
    t.column :amount, currency: true
  end

  # Displays details of one financial year selected with +params[:id]+
  def show
    return unless @financial_year = find_and_check
    respond_to do |format|
      format.html do
        if @financial_year.closed? and @financial_year.account_balances.empty?
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
    redirect_to_back
  end


  def close
    # Launch close process
    return unless @financial_year = find_and_check
    if request.post?
      params[:journal_id] = Journal.create!(:nature => "renew").id if params[:journal_id]=="0"
      if @financial_year.close(params[:financial_year][:stopped_on].to_date, :renew_id => params[:journal_id])
        notify_success(:closed_financial_years)
        redirect_to(action: :index)
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
    @financial_year.started_on = f.stopped_on + 1 unless f.nil?
    @financial_year.started_on ||= Date.today
    @financial_year.stopped_on = ((@financial_year.started_on - 1) >> 12).end_of_month
    @financial_year.code = @financial_year.default_code
    @financial_year.currency = @financial_year.previous.currency if @financial_year.previous
    @financial_year.currency ||= Entity.of_company.currency
    # render_restfully_form
  end

  def generate_last_journal_entry
    return unless @financial_year = find_and_check
    if request.get?
      params[:financial_assets_depreciations] ||= 1
    elsif request.post?
      # TODO: Defines journal to save the entry
      @financial_year.generate_last_journal_entry(params)
      redirect_to backend_journal_entry_url(@financial_year.last_journal_entry)
    end
    t3e @financial_year.attributes
  end

end
