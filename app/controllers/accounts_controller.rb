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

class AccountsController < ApplicationController
  manage_restfully :number=>"params[:number]"

  list(:entities, :conditions=>["#{Entity.table_name}.company_id = ? AND ? IN (client_account_id, supplier_account_id, attorney_account_id)", ['@current_company.id'], ['session[:current_account_id]']], :order=>"created_at DESC") do |t|
    t.column :code, :url=>true
    t.column :full_name, :url=>true
    t.column :label, :through=>:client_account, :url=>true
    t.column :label, :through=>:supplier_account, :url=>true
    t.column :label, :through=>:attorney_account, :url=>true
  end

  list(:journal_entry_lines, :conditions=>["#{JournalEntryLine.table_name}.company_id = ? AND #{JournalEntryLine.table_name}.account_id = ?", ['@current_company.id'], ['session[:current_account_id]']], :order=>"entry_id DESC, #{JournalEntryLine.table_name}.position") do |t|
    t.column :name, :through=>:journal, :url=>true
    t.column :number, :through=>:entry, :url=>true
    t.column :printed_on, :through=>:entry, :datatype=>:date, :label=>:column
    t.column :name
    t.column :state_label
    t.column :letter
    t.column :debit
    t.column :credit
  end

  list(:reconciliation, :model=>:journal_entry_lines, :joins=>[:entry, :account], :conditions=>account_reconciliation_conditions, :order=>"accounts.number, journal_entries.printed_on") do |t|
    t.column :number, :through=>:account, :url=>{:action=>:mark}
    t.column :name, :through=>:account, :url=>{:action=>:mark}
    t.column :number, :through=>:entry
    t.column :name
    t.column :debit
    t.column :credit
  end

  list(:conditions=>accounts_conditions, :order=>"number ASC", :per_page=>20) do |t|
    t.column :number, :url=>true
    t.column :name, :url=>true
    t.column :reconcilable
    t.column :comment
    t.action :edit
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.destroyable\?"
  end

  # Displays details of one account selected with +params[:id]+
  def show
    return unless @account = find_and_check(:account)
    session[:current_account_id] = @account.id
    @totals = {}
    @totals[:debit]  = @account.journal_entry_lines.sum(:debit)
    @totals[:credit] = @account.journal_entry_lines.sum(:credit)
    @totals[:balance_debit] = 0.0
    @totals[:balance_credit] = 0.0
    @totals["balance_#{@totals[:debit]>@totals[:credit] ? 'debit' : 'credit'}".to_sym] = (@totals[:debit]-@totals[:credit]).abs    
    t3e @account.attributes
  end

  def mark
    return unless @account = find_and_check(:account)
    if request.post?
      if params[:journal_entry_line]
        letter = @account.mark(params[:journal_entry_line].select{|k,v| v[:to_mark].to_i==1}.collect{|k,v| k.to_i})
        if letter.nil?
          notify_error_now(:cannot_mark_entry_lines)
        else
          notify_success_now(:journal_entry_lines_marked_with_letter, :letter=>letter)
        end
      else
        notify_warning_now(:select_entry_lines_to_mark_together)
      end
    end
    t3e @account.attributes
  end

  def reconciliation
    params[:mode] ||= :clients
    # session[:account_prefix] = @current_company.preferred("third_#{params[:mode]}_accounts").to_s+"%"
    session[:account_key] = params[:key]
  end

  def unmark
    return unless @account = find_and_check(:account)
    if request.post? and params[:letter]
      @account.unmark(params[:letter])
    end
    redirect_to_current
  end

  # Displays the main page with the list of accounts
  def index
  end

  def load
    if request.post?
      locale, name = params[:list].split(".")
      
      ActiveRecord::Base.transaction do
        # Unset reconcilable old third accounts
        if params[:unset_reconcilable_old_third_accounts]
          @current_company.accounts.update_all({:reconcilable=>false}, @current_company.reconcilable_prefixes.collect{|p| "number LIKE '#{p}%'"}.join(" OR "))
        end
        
        # Updates prefix
        for key, data in params[:preference]
          @current_company.prefer! key, data[:value]
        end
        
        # Load accounts
        @current_company.load_accounts(name, :locale=>locale, :reconcilable=>(params[:set_reconcilable_new_but_existing_third_accounts].to_i>0))
      end
      redirect_to :action=>:accounts
    end
  end

end
