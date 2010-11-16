# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2009-2010 Brice Texier, Thibaud Merigon
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

class AccountancyController < ApplicationController
  include ActionView::Helpers::FormOptionsHelper
  
  dyli(:account, ["number:X%", :name], :conditions => {:company_id=>['@current_company.id']})
  
  
  # Generates code to check state crit
  def self.journal_entry_states_crit(name, conditions='c')
    variable = "session[:#{name}]" unless name.is_a? String
    code = ""
    code += "#{conditions}[0] += \" AND (false\"\n"
    code += "#{conditions}[0] += \" OR (#{JournalEntryLine.table_name}.state = 'draft')\" if #{variable}[:draft] == '1'\n"
    code += "#{conditions}[0] += \" OR (#{JournalEntryLine.table_name}.state = 'confirmed')\" if #{variable}[:confirmed] == '1'\n"
    code += "#{conditions}[0] += \" OR (#{JournalEntryLine.table_name}.state = 'closed')\" if #{variable}[:closed] == '1'\n"
    code += "#{conditions}[0] += \")\"\n"    
    return code
  end


  # Generates code to check period crit
  def self.journal_period_crit(name, conditions='c')
    variable = "session[:#{name}]" unless name.is_a? String
    code = ""
    code += "started_on = stopped_on = nil\n"
    code += "if #{variable}[:period]=='interval'\n"
    code += "  started_on, stopped_on = #{variable}[:started_on], #{variable}[:stopped_on]\n"
    code += "else\n"
    code += "  started_on, stopped_on = #{variable}[:period].split('_')[0..1]\n"
    code += "end\n"
    code += "if (started_on.to_date rescue nil)\n"
    code += "  #{conditions}[0]+=' AND #{JournalEntry.table_name}.printed_on>=?'\n"
    code += "  #{conditions} << started_on.to_date\n"
    code += "end\n"
    code += "if (stopped_on.to_date rescue nil)\n"
    code += "  #{conditions}[0]+=' AND #{JournalEntry.table_name}.printed_on<=?'\n"
    code += "  #{conditions} << stopped_on.to_date\n"
    code += "end\n"
    return code
  end

  # Generates code to check journals crit
  def self.journals_crit(name, conditions='c')
    variable = "session[:#{name}]" unless name.is_a? String
    code = ""
    code += "#{conditions}[0] += ' AND #{JournalEntryLine.table_name}.journal_id IN (?)'\n"
    code += "if #{variable}[:journals].is_a?(Hash)\n"
    code += "  #{variable}[:journals] = #{variable}[:journals].select{|k, v| k.to_s.match(/^\d+$/) and v.to_i == 1}.collect{|k, v| k.to_i}\n"
    code += "end\n"
    code += "#{conditions} << #{variable}[:journals]\n"
    return code
  end

  # Generates code to check accounts ranges
  def self.accounts_range_crit(name, conditions='c')
    variable = "session[:#{name}]" unless name.is_a? String
    code = ""
    code += "unless #{variable}[:accounts].match(/\(/)\n"
    code += "  ac, params[:accounts] = Account.range_condition(#{variable}[:accounts])\n"
    code += "  #{variable}[:accounts] = ' AND ('+ac+')'\n"
    code += "end\n"
    code += "#{conditions}[0] += #{variable}[:accounts]\n"
    return code
  end


  # 
  def index
  end

  # this method displays the form to choose the journal and financial_year.
  def bookkeep
    params[:finish_bookkeeping_on] = (params[:finish_bookkeeping_on]||Date.today).to_date rescue Date.today
    @natures = [:sales_invoice, :incoming_payment_use, :incoming_payment, :deposit, :purchase_order, :outgoing_payment_use, :outgoing_payment]

    if request.get?
      notify(:bookkeeping_works_only_with, :information, :now, :list=>@natures.collect{|x| x.to_s.classify.constantize.model_name.human}.to_sentence)
      @step = 1
    elsif request.put?
      @step = 2
    elsif request.post?
      @step = 3
    end


    if @step >= 2
      session[:finish_bookkeeping_on] = params[:finish_bookkeeping_on]
      @records = {}
      for nature in @natures
        conditions = ["accounted_at IS NULL AND created_at <= ?", session[:finish_bookkeeping_on].to_time]
        if nature == :purchase_order
          conditions[0] += " AND shipped = ? " 
          conditions << true
        end
        @records[nature] = @current_company.send(nature.to_s.pluralize).find(:all, :conditions=>conditions)
      end

      if @step == 3
        state = (params[:save_in_draft].to_i == 1 ? :draft : :confirmed)
        for nature in @natures
          for record in @records[nature]
            record.bookkeep(:create, state)
          end
        end
        notify(:bookkeeping_is_finished, :success)
        redirect_to :action=>(state == :draft ? :draft : :bookkeep)
      end
    end
    

  end


  def self.accounts_conditions
    code  = search_conditions(:accounts, [:name, :number, :comment])+"[0] += ' AND number LIKE ?'\n"
    code += "c << session[:account_prefix]\n"
    code += "if (session[:used_accounts])\n"
    code += "  c[0]+=' AND id IN (SELECT account_id FROM #{JournalEntryLine.table_name} AS journal_entry_lines JOIN #{JournalEntry.table_name} AS journal_entries ON (entry_id=journal_entries.id) WHERE created_on BETWEEN ? AND ? AND journal_entry_lines.company_id = ?)'\n"
    code += "  c+=[(params[:started_on].to_date rescue Date.civil(1901,1,1)), (params[:stopped_on].to_date rescue Date.civil(1901,1,1)), @current_company.id]\n"
    code += "end\n"
    code += "c"
    return code
  end

  create_kame(:accounts, :conditions=>accounts_conditions, :order=>"number ASC", :per_page=>20) do |t|
    t.column :number, :url=>{:action=>:account}
    t.column :name, :url=>{:action=>:account}
    t.action :account_update
    t.action :account_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.destroyable\?"
  end
  
  # lists all the accounts with the credit, the debit and the balance for each of them.
  def accounts
    session[:account_prefix] = params[:prefix].to_s+'%'
    session[:used_accounts] = params[:used_accounts]
    session[:started_on] = params[:started_on]
    session[:stopped_on] = params[:stopped_on]
    session[:account_key] = params[:key]
  end

  def accounts_load
    if request.post?
      locale, name = params[:list].split(".")
      @current_company.load_accounts(name, locale)
      redirect_to :action=>:accounts
    end
  end

  manage :accounts, :number=>"params[:number]"

  create_kame(:account_journal_entry_lines, :model=>:journal_entry_lines, :conditions=>["company_id = ? AND account_id = ?", ['@current_company.id'], ['session[:current_account_id]']], :order=>"entry_id DESC, #{JournalEntryLine.table_name}.position") do |t|
    t.column :name, :through=>:journal, :url=>{:action=>:journal}
    t.column :number, :through=>:entry, :url=>{:action=>:journal_entry}
    t.column :printed_on, :through=>:entry, :datatype=>:date, :label=>:column
    t.column :name
    t.column :state_label
    t.column :debit
    t.column :credit
    t.column :letter
  end

  create_kame(:account_entities, :model=>:entities, :conditions=>["company_id = ? AND ? IN (client_account_id, supplier_account_id, attorney_account_id)", ['@current_company.id'], ['session[:current_account_id]']], :order=>"created_at DESC") do |t|
    t.column :code, :url=>{:action=>:entity, :controller=>:relations}
    t.column :full_name, :url=>{:action=>:entity, :controller=>:relations}
    t.column :label, :through=>:client_account, :url=>{:action=>:account}
    t.column :label, :through=>:supplier_account, :url=>{:action=>:account}
    t.column :label, :through=>:attorney_account, :url=>{:action=>:account}
  end

#   create_kame(:account_children, :model=>:accounts, :conditions=>["company_id = ? AND number LIKE ?", ['@current_company.id'], ['session[:current_account_number]+"%"']], :order=>"number ASC") do |t|
#     t.column :number, :url=>{:action=>:account}
#     t.column :name, :url=>{:action=>:account}
#     t.action :account_update
#     t.action :account_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
#   end

  def account
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


  def self.unmarked_journal_entry_lines_conditions
    code  = search_conditions(:accounts, :accounts=>[:name, :number, :comment], :journal_entries=>[:number], JournalEntryLine.table_name=>[:name, :debit, :credit])+"[0] += ' AND accounts.number LIKE ?'\n"
    code += "c << session[:account_prefix]\n"
    code += "c[0] += ' AND "+JournalEntryLine.connection.length(JournalEntryLine.connection.trim("COALESCE(letter, \\'\\')"))+" = 0'\n"
    code += "c"
    return code
  end
  
  create_kame(:unmarked_journal_entry_lines, :model=>:journal_entry_lines, :joins=>"JOIN #{JournalEntry.table_name} AS journal_entries ON (entry_id=journal_entries.id) JOIN #{Account.table_name} AS accounts ON (account_id=accounts.id)", :conditions=>unmarked_journal_entry_lines_conditions, :order=>"letter DESC, accounts.number, credit") do |t|
    t.column :number, :through=>:account, :url=>{:action=>:account_mark}
    t.column :name, :through=>:account, :url=>{:action=>:account_mark}
    t.column :number, :through=>:entry
    t.column :name
    t.column :debit
    t.column :credit
  end

  # This method allows to make marking for the client and supplier accounts.
  def unmarked_journal_entry_lines
    params[:mode] ||= :clients
    session[:account_prefix] = @current_company.preferred("third_#{params[:mode]}_accounts").to_s+"%"
    session[:account_key] = params[:key]
  end


  # this method displays the array for make marking.
  def account_mark
    return unless @account = find_and_check(:account)
    fy = @current_company.current_financial_year
    params[:stopped_on] = (params[:stopped_on]||(fy ? fy.stopped_on : Date.today)).to_date
    params[:started_on] = (params[:started_on]||(fy ? fy.started_on : params[:stopped_on]-1.month+1.day)).to_date
    if request.post?
      if params[:journal_entry_line]
        journal_entry_lines = params[:journal_entry_line].collect{|k,v| ((v[:to_mark]=="1" and @current_company.journal_entry_lines.find_by_id(k)) ? k.to_i : nil)}.compact
        @account.mark(journal_entry_lines)
      else
        notify(:select_entries_to_mark_together, :warning, :now)
      end
    end
    @journal_entry_lines = @account.markable_entry_lines(params[:started_on], params[:stopped_on])
    @letter = @account.new_letter
    t3e @account.attributes, :started_on=>params[:started_on], :stopped_on=>params[:stopped_on]
  end

  # this method displays the array for make marking.
  def account_unmark
    return unless @account = find_and_check(:account)
    if request.post? and params[:letter]
      @account.unmark(params[:letter])
    end
    redirect_to_current
  end



  def document_print
    # redirect_to :action=>:index
    @document_templates = @current_company.document_templates.find(:all, :conditions=>{:family=>"accountancy"}, :order=>:name)
    @document_template = @current_company.document_templates.find_by_family_and_code("accountancy", params[:code])
    if request.xhr?
      render :partial=>'document_options'
      return
    end
    if request.post?
      if params[:export]
        query  = "SELECT ''''||accounts.number, accounts.name, sum(COALESCE(journal_entry_lines.debit, 0)), sum(COALESCE(journal_entry_lines.credit, 0)), sum(COALESCE(journal_entry_lines.debit, 0)) - sum(COALESCE(journal_entry_lines.credit, 0))"
        query += " FROM #{JournalEntryLine.table_name} AS journal_entry_lines JOIN #{Account.table_name} AS accounts ON (account_id=accounts.id) JOIN #{JournalEntry.table_name} AS journal_entries ON (entry_id=journal_entries.id)"
        query += " WHERE printed_on BETWEEN #{ActiveRecord::Base.connection.quote(params[:started_on].to_date)} AND #{ActiveRecord::Base.connection.quote(params[:stopped_on].to_date)}"
        query += " GROUP BY accounts.name, accounts.number"
        query += " ORDER BY accounts.number"
        begin
          result = ActiveRecord::Base.connection.select_rows(query)
          result.insert(0, ["N°Compte", "Libellé du compte", "Débit", "Crédit", "Solde"])
          result.insert(0, ["Balance du #{params[:started_on]} au #{params[:stopped_on]}"])
          csv_string = FasterCSV.generate do |csv|
            for line in result
              csv << line
            end
          end
          send_data(csv_string, :filename=>'export.csv', :type=>Mime::CSV)
        rescue Exception => e 
          notify(:exception_raised, :error, :now, :message=>e.message)
        end
      else
        redirect_to params.merge(:action=>:print, :controller=>:company)
      end
    end
    @document_template ||= @document_templates[0]
  end


  def balance
    if params[:started_on] and params[:stopped_on]
      @balance = @current_company.balance(params)
    end
  end

  def self.general_ledger_conditions(options={})
    conn = ActiveRecord::Base.connection
    code  = "session[:general_ledger] ||= {}\n"
    code += "c=['journal_entries.company_id=?', @current_company.id]\n"
    # period
    code += "c[0]+=' AND journal_entries.printed_on BETWEEN ? AND ?'\n"
    code += "c+=[session[:general_ledger][:started_on], session[:general_ledger][:stopped_on]]\n"
    # state
    code += "c[0] += \" AND (false\"\n"
    code += "c[0] += \" OR (#{JournalEntryLine.table_name}.state = 'draft')\" if session[:general_ledger][:draft] == '1'\n"
    code += "c[0] += \" OR (#{JournalEntryLine.table_name}.state = 'confirmed')\" if session[:general_ledger][:confirmed] == '1'\n"
    code += "c[0] += \" OR (#{JournalEntryLine.table_name}.state = 'closed')\" if session[:general_ledger][:closed] == '1'\n"
    code += "c[0] += \")\"\n"    
    # accounts
    code += "c[0] += ' AND ('+(session[:general_ledger][:accounts]||\"#{conn.quoted_false}\")+')'\n"
    # journals
    code += "c[0] += ' AND #{JournalEntryLine.table_name}.journal_id IN (?)'\n"
    code += "c<<session[:general_ledger][:journals]\n"    
    code += "c\n"
    return code # .gsub(/\s*\n\s*/, ";")
  end

  create_kame(:general_ledger, :model=>:journal_entry_lines, :conditions=>general_ledger_conditions, :joins=>"JOIN #{JournalEntry.table_name} AS journal_entries ON (entry_id = journal_entries.id) JOIN #{Account.table_name} AS accounts ON (account_id = accounts.id)", :order=>"accounts.number, journal_entries.number, #{JournalEntryLine.table_name}.position") do |t|
    t.column :number, :through=>:account, :url=>{:action=>:account}
    t.column :name, :through=>:account, :url=>{:action=>:account}
    t.column :number, :through=>:entry, :url=>{:action=>:journal_entry}
    t.column :printed_on, :through=>:entry, :datatype=>:date
    t.column :name
    t.column :debit
    t.column :credit
  end

  def general_ledger
    session[:general_ledger] = {}
    fy = @current_company.current_financial_year
    params[:started_on] = params[:started_on].to_date rescue (fy ? fy.started_on : Date.today)
    params[:stopped_on] = params[:stopped_on].to_date rescue (fy ? fy.stopped_on : Date.today)
    params[:stopped_on] = params[:started_on] if params[:started_on] > params[:stopped_on]

    if params[:accounts]
      conn = ActiveRecord::Base.connection
      valid_expr = /^\d(\d(\d[0-9A-Z]*)?)?$/
      accounts = "false"
      expression = ""
      for expr in params[:accounts].split(/[^0-9A-Z\-\*]+/)
        if expr.match(/\-/)
          start, finish = expr.split(/\-+/)[0..1]
          next unless start < finish and start.match(valid_expr) and finish.match(valid_expr)
          max = [start.length, finish.length].max
          accounts += " OR #{conn.substr('accounts.number', 1, max)} BETWEEN #{conn.quote(start.ljust(max, '0'))} AND #{conn.quote(finish.ljust(max, 'Z'))}"
          expression += " #{start}-#{finish}"
        else
          next unless expr.match(valid_expr)
          accounts += " OR accounts.number LIKE #{conn.quote(expr+'%')}"
          expression += " #{expr}"
        end
      end
      session[:general_ledger][:accounts] = accounts
      params[:accounts] = expression.strip
    end

    for key in [:started_on, :stopped_on, :draft, :confirmed, :closed]
      session[:general_ledger][key] = params[key]
    end

    journals = []
    for name, value in params.select{|k, v| k.to_s.match(/^journal_\d+$/) and v.to_i == 1}
      journals << @current_company.journals.find(name.split(/\_/)[-1].to_i).id rescue nil
    end
    session[:general_ledger][:journals] = journals.compact
  end
  
  
  create_kame(:financial_years, :conditions=>{:company_id=>['@current_company.id']}, :order=>"started_on DESC") do |t|
    t.column :code, :url=>{:action=>:financial_year}
    t.column :closed
    t.column :started_on,:url=>{:action=>:financial_year}
    t.column :stopped_on,:url=>{:action=>:financial_year}
    t.action :financial_year_close, :if => '!RECORD.closed and RECORD.closable?'
    t.action :financial_year_update, :if => '!RECORD.closed'  
    t.action :financial_year_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if => '!RECORD.closed'  
  end

  # lists all the cashes with the mainly characteristics. 
  def financial_years
  end

  def financial_year
    return unless @financial_year = find_and_check(:financial_years)
    @financial_year.compute_balances # TODELETE !!!
    t3e @financial_year.attributes
  end
  
  # this action creates a financial_year with a form.
  def financial_year_create
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
    
    render_form
  end
  
  
  # this action updates a financial_year with a form.
  def financial_year_update
    return unless @financial_year = find_and_check(:financial_years)
    if request.post? or request.put?
      @financial_year.attributes = params[:financial_year]
      return if save_and_redirect(@financial_year)
    end
    t3e @financial_year.attributes
    render_form
  end
  
  # this action deletes a financial_year.
  def financial_year_delete
    return unless @financial_year = find_and_check(:financial_years)
    if request.post? or request.delete?
      FinancialYear.destroy @financial_year unless @financial_year.journal_entries.size > 0
    end
    redirect_to :action => :financial_years
  end
  
  
  # This method allows to close the financial_year.
  def financial_year_close
    if params[:id].nil?
      # We need an ID to close some financial year
      if financial_year = @current_company.closable_financial_year
        redirect_to :action=>:financial_year_close, :id=>financial_year.id
      else
        notify(:no_closable_financial_year, :information)
        redirect_to :action=>:financial_years
      end
    else
      # Launch close process
      return unless @financial_year = find_and_check(:financial_year)
      if request.post?
        params[:journal_id]=@current_company.journals.create!(:nature=>"renew").id if params[:journal_id]=="0"
        if @financial_year.close(params[:financial_year][:stopped_on].to_date, :renew_id=>params[:journal_id])
          notify(:closed_financial_years, :success)
          redirect_to(:action=>:financial_years)
        end
      else
        journal = @current_company.journals.find(:first, :conditions => {:nature => "forward"})
        params[:journal_id] = (journal ? journal.id : 0)
      end    
    end
  end

  create_kame(:journals, :conditions=>{:company_id=>['@current_company.id']}, :order=>:code) do |t|
    t.column :name, :url=>{:action=>:journal}
    t.column :code, :url=>{:action=>:journal}
    t.column :nature_label
    t.column :name, :through=>:currency
    t.column :closed_on
    t.action :document_print, :url=>{:code=>:JOURNAL, :journal=>"RECORD.id"}
    t.action :journal_close, :if=>'RECORD.closable?(Date.today)', :image=>:unlock
    t.action :journal_reopen, :if=>"RECORD.reopenable\?", :image=>:lock
    t.action :journal_update
    t.action :journal_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end
  

  # 
  def journals
  end

  def self.journal_entries_conditions(options={})
    code = search_conditions(:journal_entry, JournalEntry.table_name=>[:number, :debit, :credit], JournalEntryLine.table_name=>[:name, :debit, :credit])+"[0] += ' AND #{JournalEntry.table_name}.journal_id=?'\n"
    code += "c << session[:current_journal_id]\n"
    code += "session[:journal] = {} unless session[:journal].is_a?(Hash)\n"
    code += journal_entry_states_crit(:journal)
    code += journal_period_crit(:journal)
    code += "c\n"
    return code.gsub(/\s*\n\s*/, ";")
  end

  create_kame(:journal_entry_lines, :conditions=>journal_entries_conditions, :joins=>"JOIN #{JournalEntry.table_name} ON (entry_id = #{JournalEntry.table_name}.id)", :line_class=>"(RECORD.last\? ? 'last-entry' : '')", :order=>"entry_id DESC, #{JournalEntryLine.table_name}.position") do |t|
    t.column :number, :through=>:entry, :url=>{:action=>:journal_entry}
    t.column :printed_on, :through=>:entry, :datatype=>:date
    t.column :number, :through=>:account, :url=>{:action=>:account}
    t.column :name, :through=>:account, :url=>{:action=>:account}
    t.column :name
    t.column :state_label
    t.column :debit
    t.column :credit
  end
  
  create_kame(:journal_entries, :conditions=>journal_entries_conditions, :order=>"created_at DESC") do |t|
    t.column :number, :url=>{:action=>:journal_entry}
    t.column :printed_on
    t.column :state_label
    t.column :debit
    t.column :credit
    t.action :journal_entry_update, :if=>'RECORD.updateable? '
    t.action :journal_entry_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.destroyable\?"
  end
  
  create_kame(:journal_mixed, :model=>:journal_entries, :conditions=>journal_entries_conditions, :children=>:lines, :order=>"created_at DESC", :per_page=>10) do |t|
    t.column :number, :url=>{:action=>:journal_entry}, :children=>:name
    t.column :printed_on, :datatype=>:date, :children=>false
    # t.column :label, :through=>:account, :url=>{:action=>:account}
    t.column :state_label
    t.column :debit
    t.column :credit
    t.action :journal_entry_update, :if=>'RECORD.updateable? '
    t.action :journal_entry_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.destroyable\?"
  end


  def journal_filter()
    fy = @current_company.current_financial_year
    session[:journal] = {} unless session[:journal].is_a? Hash
    session[:journal][:period] = params[:period] = params[:period]||(fy ? fy.started_on.to_s+"_"+fy.stopped_on.to_s : nil)
    session[:journal][:start]  = params[:start]  = params[:start]||(fy ? fy.started_on : Date.today)
    session[:journal][:finish] = params[:finish] = params[:finish]||(fy ? fy.stopped_on : Date.today)
    
    if action_name == "draft"
      journals = []
      for name, value in params.select{|k, v| k.to_s.match(/^journal_\d+$/) and v.to_i == 1}
        journals << @current_company.journals.find(name.split(/\_/)[-1].to_i).id rescue nil
      end
      session[:current_journal_id] = journals.compact
    end
  end


  @@journal_views = ["entry_lines", "entries", "mixed"]
  cattr_reader :journal_views

  def journal
    return unless @journal = find_and_check(:journal)
    session[:current_journal_id] = @journal.id
    # session[:journal] = params
    journal_view = @current_user.preference("interface.journal.#{@journal.code}.view")
    journal_view.value = self.journal_views[0] unless self.journal_views.include? journal_view.value
    if view = self.journal_views.detect{|x| params[:view] == x}
      journal_view.value = view
      journal_view.save
    end

    conditions = eval(self.class.journal_entries_conditions)
    @totals = {}
    @totals[:debit]  = JournalEntry.sum(:debit, :conditions=>conditions)
    @totals[:credit] = JournalEntry.sum(:credit, :conditions=>conditions)
    @totals[:balance_debit] = 0.0
    @totals[:balance_credit] = 0.0
    @totals["balance_#{@totals[:debit]>@totals[:credit] ? 'debit' : 'credit'}".to_sym] = (@totals[:debit]-@totals[:credit]).abs

    @journal_view = journal_view.value
    t3e @journal.attributes
  end


  create_kame(:draft, :model=>:journal_entry_lines, :conditions=>journal_entries_conditions(:state=>"draft"), :joins=>"JOIN #{JournalEntry.table_name} ON (entry_id = #{JournalEntry.table_name}.id)", :order=>"entry_id DESC, #{JournalEntryLine.table_name}.position") do |t|
    t.column :name, :through=>:journal, :url=>{:action=>:journal}
    t.column :number, :through=>:entry, :url=>{:action=>:journal_entry}
    t.column :printed_on, :through=>:entry, :datatype=>:date
    t.column :number, :through=>:account, :url=>{:action=>:account}
    t.column :name, :through=>:account, :url=>{:action=>:account}
    t.column :name
    t.column :debit
    t.column :credit
  end
  
  # this method lists all the entries generated in draft mode.
  def draft
    journal_filter
    if request.post? and params[:validate]
      conditions = nil
      begin
        conditions = eval(self.class.journal_entries_conditions(:state=>"draft"))
        journal_entries = @current_company.journal_entries.find(:all, :conditions=>conditions)
        undone = 0
        for entry in journal_entries
          entry.confirm if entry.can_confirm?
          undone += 1 if entry.draft?
        end
        notify(:draft_entry_lines_are_validated, :success, :now, :count=>journal_entries.size-undone)
      rescue Exception=>e
        notify(:exception_raised, :error, :now, :message=>e.message)
      end
    end
  end
  



  manage :journals, :nature=>"params[:nature]||Journal.natures[0][1]"


  # This method allows to close the journal.
  def journal_close
    return unless @journal = find_and_check(:journal)
    unless @journal.closable?
      notify(:no_closable_journal)
      redirect_to :action => :journals
      return
    end    
    if request.post?   
      if @journal.close(params[:journal][:closed_on].to_date)
        notify(:journal_closed_on, :success, :closed_on=>::I18n.l(@journal.closed_on), :journal=>@journal.name)
        redirect_to_back 
      end
    end
    t3e @journal.attributes
  end

  
  def journal_reopen
    return unless @journal = find_and_check(:journal)
    unless @journal.reopenable?
      notify(:no_reopenable_journal)
      redirect_to :action => :journals
      return
    end    
    if request.post?
      if @journal.reopen(params[:journal][:closed_on].to_date)
        notify(:journal_reopened_on, :success, :closed_on=>::I18n.l(@journal.closed_on), :journal=>@journal.name)
        redirect_to_back 
      end
    end
    t3e @journal.attributes    
  end



  create_kame(:journal_entry_entries, :model=>:journal_entry_lines, :conditions=>{:company_id=>['@current_company.id'], :entry_id=>['session[:current_journal_entry_id]']}, :order=>"entry_id DESC, position") do |t|
    t.column :name
    t.column :number, :through=>:account, :url=>{:action=>:account}
    t.column :name, :through=>:account, :url=>{:action=>:account}
    t.column :letter
    t.column :number, :through=>:bank_statement
    t.column :currency_debit
    t.column :currency_credit
  end


  def journal_entry
    return unless @journal_entry = find_and_check(:journal_entry)
    session[:current_journal_entry_id] = @journal_entry.id
    t3e @journal_entry.attributes
  end



  # Permits to write records and entries in journal
  def journal_entry_create
    return unless @journal = find_and_check(:journal, params[:journal_id])  
    session[:current_journal_id] = @journal.id
    @journal_entry = @journal.entries.build(params[:journal_entry])
    if request.post?
      @journal_entry_lines = (params[:lines]||{}).values
      if @journal_entry.save_with_lines(@journal_entry_lines)
        notify(:journal_entry_has_been_saved, :success, :number=>@journal_entry.number)
        redirect_to :action=>:journal_entry_create, :journal_id=>@journal.id # , :draft_mode=>(1 if @journal_entry.draft_mode)
      end
    else
      @journal_entry.printed_on = @journal_entry.created_on = Date.today
      @journal_entry.number = @journal.next_number
      # @journal_entry.draft_mode = true if params[:draft_mode].to_i == 1
      @journal_entry_lines = []
    end
    t3e @journal.attributes
    render_form
  end

  def journal_entry_update
    return unless @journal_entry = find_and_check(:journal_entry)
    unless @journal_entry.updateable?
      notify(:journal_entry_already_validated, :error)
      redirect_to_back
      return
    end
    @journal = @journal_entry.journal
    if request.post?
      @journal_entry.attributes = params[:journal_entry]
      @journal_entry_lines = (params[:entries]||{}).values
      if @journal_entry.save_with_lines(@journal_entry_lines)
        redirect_to_back
      end
    else
      @journal_entry_lines = @journal_entry.lines
    end
    t3e @journal_entry.attributes
    render_form
  end

  def journal_entry_delete
    return unless @journal_entry = find_and_check(:journal_entry)
    unless @journal_entry.destroyable?
      notify(:journal_entry_already_validated, :error)
      redirect_to_back
      return
    end
    if request.delete?
      @journal_entry.destroy
      notify(:record_has_been_correctly_removed, :success)
    end
    redirect_to_current
  end


  def journal_entry_line_create
    @journal_entry_line = JournalEntryLine.new
    if request.xhr?
      render :partial=>"journal_entry_line_row_form", :object=>@journal_entry_line
    else
      redirect_to_back
    end
  end







  
  create_kame(:bank_statements, :conditions=>{:company_id=>['@current_company.id']}, :order=>"started_on ASC") do |t|
    t.column :number, :url=>{:action=>:bank_statement}
    t.column :name, :through=>:cash, :url=>{:action=>:cash, :controller=>:finances}
    t.column :started_on
    t.column :stopped_on
    t.column :debit
    t.column :credit
    t.action :bank_statement_point
    t.action :bank_statement_update
    t.action :bank_statement_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  # lists all the statements in details for a precise account.
  def bank_statements  
    cashes = @current_company.cashes
    unless cashes.size>0
      notify(:need_cash_to_record_statements)
      redirect_to :action=>:cash_create, :controller=>:finances
      return
    end
    notify(:x_unpointed_journal_entry_lines, :now, :count=>@current_company.journal_entry_lines.count(:conditions=>["bank_statement_id IS NULL and account_id IN (?)", cashes.collect{|ba| ba.account_id}]))
  end


  create_kame(:bank_statement_lines, :model =>:journal_entry_lines, :conditions=>{:company_id=>['@current_company.id'], :bank_statement_id=>['session[:current_bank_statement_id]']}, :order=>"entry_id") do |t|
    t.column :name, :through=>:journal, :url=>{:action=>:journal}
    t.column :number, :through=>:entry, :url=>{:action=>:journal_entry}
    t.column :created_on, :through=>:entry, :datatype=>:date, :label=>:column
    t.column :name
    t.column :number, :through=>:account, :url=>{:action=>:account}
    t.column :debit
    t.column :credit
  end

  # Displays in details the statement choosen with its mainly characteristics.
  def bank_statement
    return unless @bank_statement = find_and_check(:bank_statement)
    session[:current_bank_statement_id] = @bank_statement.id
    t3e @bank_statement.attributes
  end
  
  manage :bank_statements, :cash_id=>"params[:cash_id]", :started_on=>"@current_company.cashes.find(params[:cash_id]).last_bank_statement.stopped_on+1 rescue (Date.today-1.month-2.days)", :stopped_on=>"@current_company.cashes.find(params[:cash_id]).last_bank_statement.stopped_on>>1 rescue (Date.today-2.days)", :redirect_to=>'{:action => :bank_statement_point, :id =>"id"}'


  # This method displays the list of entry lines recording to the bank account for the given statement.
  def bank_statement_point
    session[:statement] = params[:id]  if request.get? 
    return unless @bank_statement = find_and_check(:bank_statement)
    if request.post?
      # raise Exception.new(params[:journal_entry_line].inspect)
      @bank_statement.lines.clear
      @bank_statement.line_ids = params[:journal_entry_line].select{|k, v| v[:checked]=="1" and @current_company.journal_entry_lines.find_by_id(k)}.collect{|k, v| k.to_i}
      if @bank_statement.save
        redirect_to :action=>:bank_statements
        return
      end
    end
    @journal_entry_lines = @bank_statement.eligible_lines
    unless @journal_entry_lines.size > 0
      notify(:need_entries_to_point, :warning)
      redirect_to :action=>:bank_statements
    end    
    t3e @bank_statement.attributes, :cash => @bank_statement.cash.name
  end



end



