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

class AccountsController < AdminController
  manage_restfully :number => "params[:number]"

  unroll
  unroll :deposit_pending_payments
  unroll :attorney_thirds
  unroll :client_thirds
  unroll :supplier_thirds
  unroll :charges
  unroll :banks
  unroll :cashes

  def self.accounts_conditions
    code  = ""
    code << light_search_conditions(Account.table_name => [:name, :number, :comment])
    code << "[0] += ' AND number LIKE ?'\n"
    code << "c << params[:prefix].to_s+'%'\n"
    code << "if params[:used_accounts].to_i == 1\n"
    code << "  c[0] += ' AND id IN (SELECT account_id FROM #{JournalEntryLine.table_name} AS jel JOIN #{JournalEntry.table_name} AS je ON (entry_id=je.id) WHERE '+JournalEntry.period_condition(params[:period], params[:started_on], params[:stopped_on], 'je')+')'\n"
    code << "end\n"
    code << "c\n"
    # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
    return code
  end

  list(:conditions => accounts_conditions, :order => "number ASC", :per_page => 20) do |t|
    t.column :number, :url => true
    t.column :name, :url => true
    t.column :reconcilable
    t.column :comment
    t.action :edit
    t.action :destroy, :if => "RECORD.destroyable\?"
  end

  # Displays the main page with the list of accounts
  def index
  end

  def self.account_moves_conditions(options={})
    code = ""
    code << light_search_conditions({:journal_entry_line => [:name, :debit, :credit, :original_debit, :original_credit], :journal_entry => [:number]}, :conditions => "c", :variable => "params[:b]")+"\n"
    code << journal_period_crit("params")
    code << journal_entries_states_crit("params")
    # code << journals_crit("params")
    code << "c[0] << ' AND #{JournalEntryLine.table_name}.account_id=?'\n"
    code << "c << session[:current_account_id]\n"
    code << "c\n"
    return code
  end

  list(:journal_entry_lines, :joins => :entry, :conditions => account_moves_conditions, :order => "entry_id DESC, #{JournalEntryLine.table_name}.position") do |t|
    t.column :name, :through => :journal, :url => true
    t.column :number, :through => :entry, :url => true
    t.column :printed_on, :through => :entry, :datatype => :date, :label => :column
    t.column :name
    t.column :state_label
    t.column :letter
    t.column :debit, :currency => "RECORD.entry.financial_year.currency"
    t.column :credit, :currency => "RECORD.entry.financial_year.currency"
  end

  list(:entities, :conditions => ["? IN (client_account_id, supplier_account_id, attorney_account_id)", ['session[:current_account_id]']], :order => "created_at DESC") do |t|
    t.column :code, :url => true
    t.column :full_name, :url => true
    t.column :label, :through => :client_account, :url => true
    t.column :label, :through => :supplier_account, :url => true
    t.column :label, :through => :attorney_account, :url => true
  end

  # Displays details of one account selected with +params[:id]+
  def show
    return unless @account = find_and_check
    session[:current_account_id] = @account.id
    t3e @account
  end

  def self.account_reconciliation_conditions
    code  = search_conditions(:accounts, :accounts => [:name, :number, :comment], :journal_entries => [:number], JournalEntryLine.table_name => [:name, :debit, :credit])+"[0] += ' AND accounts.reconcilable = ?'\n"
    code << "c << true\n"
    code << "c[0] += ' AND "+JournalEntryLine.connection.length(JournalEntryLine.connection.trim("COALESCE(letter, \\'\\')"))+" = 0'\n"
    code << "c"
    return code
  end

  list(:reconciliation, :model => :journal_entry_lines, :joins => [:entry, :account], :conditions => account_reconciliation_conditions, :order => "accounts.number, journal_entries.printed_on") do |t|
    t.column :number, :through => :account, :url => {:action => :mark}
    t.column :name, :through => :account, :url => {:action => :mark}
    t.column :number, :through => :entry
    t.column :name
    t.column :debit, :currency => "RECORD.entry.financial_year.currency"
    t.column :credit, :currency => "RECORD.entry.financial_year.currency"
  end

  def reconciliation
    session[:account_key] = params[:q]
  end

  def mark
    return unless @account = find_and_check(:account)
    if request.post?
      if params[:journal_entry_line]
        letter = @account.mark(params[:journal_entry_line].select{|k,v| v[:to_mark].to_i==1}.collect{|k,v| k.to_i})
        if letter.nil?
          notify_error_now(:cannot_mark_entry_lines)
        else
          notify_success_now(:journal_entry_lines_marked_with_letter, :letter => letter)
        end
      else
        notify_warning_now(:select_entry_lines_to_mark_together)
      end
    end
    t3e @account.attributes
  end

  def unmark
    return unless @account = find_and_check(:account)
    @account.unmark(params[:letter]) if params[:letter]
    redirect_to_current
  end

  def load
    if request.post?
      locale, name = params[:list].split(".")
      Account.load_chart(name, :locale => locale)
      redirect_to_back
    end
  end

end
