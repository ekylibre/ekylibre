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

class BankStatementsController < ApplicationController
  manage_restfully :cash_id=>"params[:cash_id]", :started_on=>"@current_company.cashes.find(params[:cash_id]).last_bank_statement.stopped_on+1 rescue (Date.today-1.month-2.days)", :stopped_on=>"@current_company.cashes.find(params[:cash_id]).last_bank_statement.stopped_on>>1 rescue (Date.today-2.days)", :redirect_to=>'{:action => :point, :id =>"id"}'

  list(:conditions=>{:company_id=>['@current_company.id']}, :order=>"started_on DESC") do |t|
    t.column :name, :through=>:cash, :url=>true
    t.column :number, :url=>true
    t.column :started_on
    t.column :stopped_on
    t.column :debit
    t.column :credit
    t.action :point
    t.action :edit
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  # Displays the main page with the list of bank statements
  def index
    cashes = @current_company.self_bank_accounts
    unless cashes.size>0
      notify(:need_cash_to_record_statements)
      redirect_to new_cash_url
      return
    end
    notify_now(:x_unpointed_journal_entry_lines, :count=>@current_company.journal_entry_lines.count(:conditions=>["bank_statement_id IS NULL and account_id IN (?)", cashes.collect{|ba| ba.account_id}]))
  end

  list(:lines, :model =>:journal_entry_lines, :conditions=>{:company_id=>['@current_company.id'], :bank_statement_id=>['session[:current_bank_statement_id]']}, :order=>"entry_id") do |t|
    t.column :name, :through=>:journal, :url=>true
    t.column :number, :through=>:entry, :url=>true
    t.column :created_on, :through=>:entry, :datatype=>:date, :label=>:column
    t.column :name
    t.column :number, :through=>:account, :url=>true
    t.column :debit
    t.column :credit
  end

  # Displays details of one bank statement selected with +params[:id]+
  def show
    return unless @bank_statement = find_and_check(:bank_statement)
    session[:current_bank_statement_id] = @bank_statement.id
    t3e @bank_statement.attributes
  end

  def point
    session[:statement] = params[:id]  if request.get? 
    return unless @bank_statement = find_and_check(:bank_statement)
    if request.post?
      # raise Exception.new(params[:journal_entry_line].inspect)
      @bank_statement.lines.clear
      @bank_statement.line_ids = params[:journal_entry_line].select{|k, v| v[:checked]=="1" and @current_company.journal_entry_lines.find_by_id(k)}.collect{|k, v| k.to_i}
      if @bank_statement.save
        redirect_to :action=>:index
        return
      end
    end
    @journal_entry_lines = @bank_statement.eligible_lines
    unless @journal_entry_lines.size > 0
      notify_warning(:need_entries_to_point)
      redirect_to :action=>:index
    end    
    t3e @bank_statement.attributes, :cash => @bank_statement.cash.name
  end

end
