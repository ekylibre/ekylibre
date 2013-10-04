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

class Backend::JournalEntriesController < BackendController

  unroll
  
  # FIXME Currency RECORD.entry.real_currency does not exist.
  list(:items, :model => :journal_entry_items, :conditions => {:entry_id => ['session[:current_journal_entry_id]']}, :order => "entry_id DESC, position") do |t|
    t.column :name
    t.column :number, through: :account, url: true
    t.column :name, through: :account, url: true
    t.column :number, through: :bank_statement, url: true
    t.column :real_debit#, :currency => "RECORD.entry.real_currency"
    t.column :real_credit#, :currency => "RECORD.entry.real_currency"
    t.column :debit#, :currency => "RECORD.entry.financial_year.currency"
    t.column :credit#, :currency => "RECORD.entry.financial_year.currency"
  end
  
    # FIXME RECORD.real_currency does not exist
  list( :children => :items, :order => "created_at DESC", :per_page => 10) do |t|
    t.column :number, url: true, :children => :name
    t.column :printed_on, :datatype => :date, :children => false
    t.column :state_label
    t.column :real_debit#, :currency => {:body => :real_currency, :children => "RECORD.real_currency"}
    t.column :real_credit#, :currency => {:body => :real_currency, :children => "RECORD.real_currency"}
    t.action :edit, :if => :updateable?
    t.action :destroy, :if => :destroyable?
  end
  
  # Displays the main page with the list of journal_entries
  def index
  end


  # Displays details of one journal entry selected with +params[:id]+
  def show
    return unless @journal_entry = find_and_check(:journal_entry)
    session[:current_journal_entry_id] = @journal_entry.id
    t3e @journal_entry.attributes
  end


  def new
    return unless @journal = find_and_check(:journal, params[:journal_id])
    session[:current_journal_id] = @journal.id
    @journal_entry = @journal.entries.build(params[:journal_entry])
    @journal_entry.printed_on = params[:printed_on]||Date.today
    @journal_entry.number = @journal.next_number
    @journal_entry_items = []
    if request.xhr?
      render(:partial => 'journal_entries/exchange_rate_form')
    else
      t3e @journal.attributes
      # render_restfully_form
    end
  end


  def create
    return unless @journal = find_and_check(:journal, params[:journal_id])
    session[:current_journal_id] = @journal.id
    @journal_entry = @journal.entries.build(params[:journal_entry])
    @journal_entry_items = (params[:items]||{}).values
    # raise @journal_entry_items.inspect
    if @journal_entry.save_with_items(@journal_entry_items)
      notify_success(:journal_entry_has_been_saved, :number => @journal_entry.number)
      redirect_to :controller => :journal_entries, :action => :new, :journal_id => @journal.id # , :draft_mode => (1 if @journal_entry.draft_mode)
      return
    end
    t3e @journal.attributes
    # render_restfully_form
  end

  def destroy
    return unless @journal_entry = find_and_check(:journal_entry)
    unless @journal_entry.destroyable?
      notify_error(:journal_entry_already_validated)
      redirect_to_back
      return
    end
    if request.delete?
      @journal_entry.destroy
      notify_success(:record_has_been_correctly_removed)
    end
    redirect_to_current
  end

  def edit
    return unless @journal_entry = find_and_check(:journal_entry)
    unless @journal_entry.updateable?
      notify_error(:journal_entry_already_validated)
      redirect_to_back
      return
    end
    @journal = @journal_entry.journal
    @journal_entry_items = @journal_entry.items
    t3e @journal_entry.attributes
    # render_restfully_form
  end

  def update
    return unless @journal_entry = find_and_check(:journal_entry)
    unless @journal_entry.updateable?
      notify_error(:journal_entry_already_validated)
      redirect_to_back
      return
    end
    @journal = @journal_entry.journal
    @journal_entry.attributes = params[:journal_entry]
    @journal_entry_items = (params[:items]||{}).values
    if @journal_entry.save_with_items(@journal_entry_items)
      redirect_to_back
      return
    end
    t3e @journal_entry.attributes
    # render_restfully_form
  end

end
