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

class FinancialYearsController < ApplicationController

  list(:conditions=>{:company_id=>['@current_company.id']}, :order=>"started_on DESC") do |t|
    t.column :code, :url=>true
    t.column :closed
    t.column :started_on,:url=>true
    t.column :stopped_on,:url=>true
    t.action :close, :if => '!RECORD.closed and RECORD.closable?'
    t.action :edit, :if => '!RECORD.closed'  
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if => '!RECORD.closed'  
  end

  # Displays details of one financial year selected with +params[:id]+
  def show
    return unless @financial_year = find_and_check(:financial_years)
    @financial_year.compute_balances # TODELETE !!!
    t3e @financial_year.attributes
  end

  def close
    if params[:id].nil?
      # We need an ID to close some financial year
      if financial_year = @current_company.closable_financial_year
        redirect_to :action=>:close, :id=>financial_year.id
      else
        notify(:no_closable_financial_year, :information)
        redirect_to :action=>:index
      end
    else
      # Launch close process
      return unless @financial_year = find_and_check(:financial_year)
      if request.post?
        params[:journal_id]=@current_company.journals.create!(:nature=>"renew").id if params[:journal_id]=="0"
        if @financial_year.close(params[:financial_year][:stopped_on].to_date, :renew_id=>params[:journal_id])
          notify(:closed_financial_years, :success)
          redirect_to(:action=>:index)
        end
      else
        journal = @current_company.journals.find(:first, :conditions => {:nature => "forward"})
        params[:journal_id] = (journal ? journal.id : 0)
      end    
    end
  end

  def new
    if request.post? 
      @financial_year = FinancialYear.new(params[:financial_year])
      @financial_year.company_id = @current_company.id
      return if save_and_redirect(@financial_year)
    else
      @financial_year = FinancialYear.new
      f = @current_company.financial_years.find(:first, :order=>"stopped_on DESC")
      @financial_year.started_on = f.stopped_on+1.day unless f.nil?
      @financial_year.started_on ||= Date.today
      @financial_year.stopped_on = (@financial_year.started_on+1.year-1.day).end_of_month
      @financial_year.code = @financial_year.default_code
    end
    
    render_restfully_form
  end

  def create
    if request.post? 
      @financial_year = FinancialYear.new(params[:financial_year])
      @financial_year.company_id = @current_company.id
      return if save_and_redirect(@financial_year)
    else
      @financial_year = FinancialYear.new
      f = @current_company.financial_years.find(:first, :order=>"stopped_on DESC")
      @financial_year.started_on = f.stopped_on+1.day unless f.nil?
      @financial_year.started_on ||= Date.today
      @financial_year.stopped_on = (@financial_year.started_on+1.year-1.day).end_of_month
      @financial_year.code = @financial_year.default_code
    end
    
    render_restfully_form
  end

  def destroy
    return unless @financial_year = find_and_check(:financial_years)
    if request.post? or request.delete?
      FinancialYear.destroy @financial_year unless @financial_year.journal_entries.size > 0
    end
    redirect_to :action => :index
  end

  def edit
    return unless @financial_year = find_and_check(:financial_years)
    if request.post? or request.put?
      @financial_year.attributes = params[:financial_year]
      return if save_and_redirect(@financial_year)
    end
    t3e @financial_year.attributes
    render_restfully_form
  end

  def update
    return unless @financial_year = find_and_check(:financial_years)
    if request.post? or request.put?
      @financial_year.attributes = params[:financial_year]
      return if save_and_redirect(@financial_year)
    end
    t3e @financial_year.attributes
    render_restfully_form
  end

  # Displays the main page with the list of financial years
  def index
  end

end
