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

class JournalsController < ApplicationController
  manage_restfully :nature=>"params[:nature]||Journal.natures[0][1]"

  @@journal_views = ["lines", "entries", "mixed"]
  cattr_reader :journal_views

  list(:lines, :model=>:journal_entry_lines, :conditions=>journal_entries_conditions, :joins=>:entry, :line_class=>"(RECORD.position==1 ? 'first-line' : '')", :order=>"entry_id DESC, #{JournalEntryLine.table_name}.position") do |t|
    t.column :number, :through=>:entry, :url=>true
    t.column :printed_on, :through=>:entry, :datatype=>:date
    t.column :number, :through=>:account, :url=>true
    t.column :name, :through=>:account, :url=>true
    t.column :name
    t.column :state_label
    t.column :debit
    t.column :credit
  end

  list(:entries, :model=>:journal_entries, :conditions=>journal_entries_conditions, :order=>"created_at DESC") do |t|
    t.column :number, :url=>true
    t.column :printed_on
    t.column :state_label
    t.column :debit
    t.column :credit
    t.action :edit, :if=>'RECORD.updateable? '
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.destroyable\?"
  end

  list(:mixed, :model=>:journal_entries, :conditions=>journal_entries_conditions, :children=>:lines, :order=>"created_at DESC", :per_page=>10) do |t|
    t.column :number, :url=>true, :children=>:name
    t.column :printed_on, :datatype=>:date, :children=>false
    # t.column :label, :through=>:account, :url=>{:action=>:account}
    t.column :state_label
    t.column :debit
    t.column :credit
    t.action :edit, :if=>'RECORD.updateable? '
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.destroyable\?"
  end

  list(:conditions=>{:company_id=>['@current_company.id']}, :order=>:code) do |t|
    t.column :name, :url=>true
    t.column :code, :url=>true
    t.column :nature_label
    t.column :name, :through=>:currency
    t.column :closed_on
    # t.action :document_print, :url=>{:code=>:JOURNAL, :journal=>"RECORD.id"}
    t.action :close, :if=>'RECORD.closable?(Date.today)', :image=>:unlock
    t.action :reopen, :if=>"RECORD.reopenable\?", :image=>:lock
    t.action :edit
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  # Displays details of one journal selected with +params[:id]+
  def show
    return unless @journal = find_and_check(:journal)
    journal_view = @current_user.preference("interface.journal.#{@journal.code}.view")
    journal_view.value = self.journal_views[0] unless self.journal_views.include? journal_view.value
    if view = self.journal_views.detect{|x| params[:view] == x}
      journal_view.value = view
      journal_view.save
    end

    @journal_view = journal_view.value
    t3e @journal.attributes
  end

  def close
    return unless @journal = find_and_check(:journal)
    unless @journal.closable?
      notify(:no_closable_journal)
      redirect_to :action => :journals
      return
    end    
    if request.post?   
      if @journal.close(params[:journal][:closed_on].to_date)
        notify_success(:journal_closed_on, :closed_on=>::I18n.l(@journal.closed_on), :journal=>@journal.name)
        redirect_to_back 
      end
    end
    t3e @journal.attributes
  end

  def reopen
    return unless @journal = find_and_check(:journal)
    unless @journal.reopenable?
      notify(:no_reopenable_journal)
      redirect_to :action => :journals
      return
    end    
    if request.post?
      if @journal.reopen(params[:journal][:closed_on].to_date)
        notify_success(:journal_reopened_on, :closed_on=>::I18n.l(@journal.closed_on), :journal=>@journal.name)
        redirect_to_back 
      end
    end
    t3e @journal.attributes    
  end

  # Displays the main page with the list of journals
  def index
  end



  list(:draft_lines, :model=>:journal_entry_lines, :conditions=>journal_entries_conditions(:with_journals=>true, :state=>:draft), :joins=>:entry, :line_class=>"(RECORD.position==1 ? 'first-line' : '')", :order=>"entry_id DESC, #{JournalEntryLine.table_name}.position") do |t|
    t.column :name, :through=>:journal, :url=>true
    t.column :number, :through=>:entry, :url=>true
    t.column :printed_on, :through=>:entry, :datatype=>:date
    t.column :number, :through=>:account, :url=>true
    t.column :name, :through=>:account, :url=>true
    t.column :name
    t.column :debit
    t.column :credit
  end
  
  # this method lists all the entries generated in draft mode.
  def draft
    if request.post? and params[:validate]
      conditions = nil
      begin
        conditions = eval(self.class.journal_entries_conditions(:with_journals=>true, :state=>:draft))
        journal_entries = @current_company.journal_entries.find(:all, :conditions=>conditions)
        undone = 0
        for entry in journal_entries
          entry.confirm if entry.can_confirm?
          undone += 1 if entry.draft?
        end
        notify_success_now(:draft_entry_lines_are_validated, :count=>journal_entries.size-undone)
      rescue Exception=>e
        notify_error_now(:exception_raised, :message=>e.message)
      end
    end
  end


  def bookkeep
    params[:stopped_on] = params[:stopped_on].to_date rescue Date.today
    params[:started_on] = params[:started_on].to_date rescue (params[:stopped_on] - 1.year).beginning_of_month
    @natures = [:sale, :incoming_payment_use, :incoming_payment, :deposit, :purchase, :outgoing_payment_use, :outgoing_payment, :cash_transfer]

    if request.get?
      notify_now(:bookkeeping_works_only_with, :list=>@natures.collect{|x| x.to_s.classify.constantize.model_name.human}.to_sentence)
      @step = 1
    elsif request.put?
      @step = 2
    elsif request.post?
      @step = 3
    end

    if @step >= 2
      session[:stopped_on] = params[:stopped_on]
      session[:started_on] = params[:started_on]
      @records = {}
      for nature in @natures
        conditions = ["created_at BETWEEN ? AND ?", session[:started_on].to_time.beginning_of_day, session[:stopped_on].to_time.end_of_day]
        @records[nature] = @current_company.send(nature.to_s.pluralize).find(:all, :conditions=>conditions)
      end

      if @step == 3
        state = (params[:save_in_draft].to_i == 1 ? :draft : :confirmed)
        for nature in @natures
          for record in @records[nature]
            record.bookkeep(:create, state)
          end
        end
        notify_success(:bookkeeping_is_finished)
        redirect_to :action=>(state == :draft ? :draft : :bookkeep)
      end
    end
    

  end

  
  def balance
    if params[:period]
      @balance = @current_company.balance(params) 
    end
  end

  def self.general_ledger_conditions(options={})
    conn = ActiveRecord::Base.connection
    code = ""
    code += "c=['journal_entries.company_id=?', @current_company.id]\n"
    code += journal_period_crit("params")
    code += journal_entries_states_crit("params")
    code += accounts_range_crit("params")
    code += journals_crit("params")
    code += "c\n"
    # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
    return code # .gsub(/\s*\n\s*/, ";")
  end

  list(:general_ledger, :model=>:journal_entry_lines, :conditions=>general_ledger_conditions, :joins=>[:entry, :account], :order=>"accounts.number, journal_entries.number, #{JournalEntryLine.table_name}.position") do |t|
    t.column :number, :through=>:account, :url=>true
    t.column :name, :through=>:account, :url=>true
    t.column :number, :through=>:entry, :url=>true
    t.column :printed_on, :through=>:entry, :datatype=>:date
    t.column :name
    t.column :debit
    t.column :credit
  end

  def general_ledger
  end  

  def reports
    # redirect_to :action=>:index
    @document_templates = @current_company.document_templates.find(:all, :conditions=>{:family=>"accountancy", :nature=>["journal", "general_journal", "general_ledger"]}, :order=>:name)
    @document_template = @current_company.document_templates.find_by_family_and_code("accountancy", params[:code])
    if request.xhr?
      render :partial=>'options'
      return
    end
    if params[:export] == "balance"
      query  = "SELECT ''''||accounts.number, accounts.name, sum(COALESCE(journal_entry_lines.debit, 0)), sum(COALESCE(journal_entry_lines.credit, 0)), sum(COALESCE(journal_entry_lines.debit, 0)) - sum(COALESCE(journal_entry_lines.credit, 0))"
      query += " FROM #{JournalEntryLine.table_name} AS journal_entry_lines JOIN #{Account.table_name} AS accounts ON (account_id=accounts.id) JOIN #{JournalEntry.table_name} AS journal_entries ON (entry_id=journal_entries.id)"
      query += " WHERE journal_entry_lines.company_id=#{@current_company.id} AND printed_on BETWEEN #{ActiveRecord::Base.connection.quote(params[:started_on].to_date)} AND #{ActiveRecord::Base.connection.quote(params[:stopped_on].to_date)}"
      query += " GROUP BY accounts.name, accounts.number"
      query += " ORDER BY accounts.number"
      begin
        result = ActiveRecord::Base.connection.select_rows(query)
        result.insert(0, ["N°Compte", "Libellé du compte", "Débit", "Crédit", "Solde"])
        result.insert(0, ["Balance du #{params[:started_on]} au #{params[:stopped_on]}"])
        csv_string = Ekylibre::CSV.generate do |csv|
          for line in result
            csv << line
          end
        end
        send_data(csv_string, :filename=>'export.csv', :type=>Mime::CSV)
      rescue Exception => e 
        notify_error_now(:exception_raised, :message=>e.message)
      end
    elsif params[:export] == "isaquare"
      path = Ekylibre::Export::AccountancySpreadsheet.generate(@current_company, params[:started_on].to_date, params[:stopped_on].to_date, @current_company.code+".ECC")
      send_file(path, :filename=>path.basename, :type=>Mime::ZIP)
    elsif params[:template]
      template = @current_company.document_templates.find_by_code(params[:template])
      nature = template.nature.to_sym
      if [:balance_sheet, :income_statement].include?(nature)
        send("render_print_#{nature}", @current_company.financial_years.find_by_id(params[:financial_year_id]))
      elsif [:general_journal, :general_ledger].include?(nature)
        send("render_print_#{nature}", params[:started_on], params[:stopped_on])
      elsif [:journal].include?(nature)
        send("render_print_#{nature}", @current_company.journals.find_by_id(params[:journal_id]), params[:started_on], params[:stopped_on])
      end
    end
    @document_template ||= @document_templates[0]
  end


end
