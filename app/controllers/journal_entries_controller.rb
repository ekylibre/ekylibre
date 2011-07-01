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

class JournalEntriesController < ApplicationController

  list(:lines, :model=>:journal_entry_lines, :conditions=>{:company_id=>['@current_company.id'], :entry_id=>['session[:current_journal_entry_id]']}, :order=>"entry_id DESC, position") do |t|
    t.column :name
    t.column :number, :through=>:account, :url=>true
    t.column :name, :through=>:account, :url=>true
    t.column :number, :through=>:bank_statement, :url=>true
    t.column :currency_debit
    t.column :currency_credit
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
    if request.post?
      @journal_entry_lines = (params[:lines]||{}).values
      if @journal_entry.save_with_lines(@journal_entry_lines)
        notify_success(:journal_entry_has_been_saved, :number=>@journal_entry.number)
        redirect_to :controller=>:journal_entries, :action=>:new, :journal_id=>@journal.id # , :draft_mode=>(1 if @journal_entry.draft_mode)
      end
    else
      @journal_entry.printed_on = @journal_entry.created_on = Date.today
      @journal_entry.number = @journal.next_number
      # @journal_entry.draft_mode = true if params[:draft_mode].to_i == 1
      @journal_entry_lines = []
    end
    t3e @journal.attributes
    render_restfully_form
  end

  def create
    return unless @journal = find_and_check(:journal, params[:journal_id])  
    session[:current_journal_id] = @journal.id
    @journal_entry = @journal.entries.build(params[:journal_entry])
    if request.post?
      @journal_entry_lines = (params[:lines]||{}).values
      if @journal_entry.save_with_lines(@journal_entry_lines)
        notify_success(:journal_entry_has_been_saved, :number=>@journal_entry.number)
        redirect_to :controller=>:journal_entries, :action=>:new, :journal_id=>@journal.id # , :draft_mode=>(1 if @journal_entry.draft_mode)
        return
      end
    else
      @journal_entry.printed_on = @journal_entry.created_on = Date.today
      @journal_entry.number = @journal.next_number
      # @journal_entry.draft_mode = true if params[:draft_mode].to_i == 1
      @journal_entry_lines = []
    end
    t3e @journal.attributes
    render_restfully_form
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
    if request.post?
      @journal_entry.attributes = params[:journal_entry]
      @journal_entry_lines = (params[:lines]||{}).values
      if @journal_entry.save_with_lines(@journal_entry_lines)
        redirect_to_back
        return
      end
    else
      @journal_entry_lines = @journal_entry.lines
    end
    t3e @journal_entry.attributes
    render_restfully_form
  end

  def update
    return unless @journal_entry = find_and_check(:journal_entry)
    unless @journal_entry.updateable?
      notify_error(:journal_entry_already_validated)
      redirect_to_back
      return
    end
    @journal = @journal_entry.journal
    if request.post?
      @journal_entry.attributes = params[:journal_entry]
      @journal_entry_lines = (params[:lines]||{}).values
      if @journal_entry.save_with_lines(@journal_entry_lines)
        redirect_to_back
        return
      end
    else
      @journal_entry_lines = @journal_entry.lines
    end
    t3e @journal_entry.attributes
    render_restfully_form
  end

end
