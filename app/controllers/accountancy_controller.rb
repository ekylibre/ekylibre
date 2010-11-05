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
  dyli(:collected_account, ["number:X%", :name], :model=>:account, :conditions => {:company_id=>['@current_company.id']})
  dyli(:paid_account, ["number:X%", :name], :model=>:account, :conditions => {:company_id=>['@current_company.id']})
  
  # 
  def index
  end

  # this method displays the form to choose the journal and financial_year.
  def accountize
    params[:finish_accountization_on] = (params[:finish_accountization_on]||Date.today).to_date rescue Date.today
    @natures = [:sales_invoice, :incoming_payment_use, :incoming_payment, :deposit, :purchase_order, :outgoing_payment_use, :outgoing_payment]

    if request.get?
      notify(:accountizing_works_only_with, :information, :now, :list=>@natures.collect{|x| x.to_s.classify.constantize.model_name.human}.to_sentence)
      @step = 1
    elsif request.put?
      @step = 2
    elsif request.post?
      @step = 3
    end


    if @step >= 2
      session[:finish_accountization_on] = params[:finish_accountization_on]
      @records = {}
      for nature in @natures
        conditions = ["accounted_at IS NULL AND created_at <= ?", session[:finish_accountization_on].to_time]
        if nature == :purchase_order
          conditions[0] += " AND shipped = ? " 
          conditions << true
        end
        @records[nature] = @current_company.send(nature.to_s.pluralize).find(:all, :conditions=>conditions)
      end

      if @step == 3
        draft = (params[:save_in_draft].to_i == 1 ? true : false)
        for nature in @natures
          for record in @records[nature]
            record.to_accountancy(:create, :draft=>draft)
          end
        end
        notify(:accountizing_is_finished, :success)
        redirect_to :action=>(draft ? :draft_entry_lines : :accountize)
      end
    end
    

  end
  





  create_kame(:cashes, :conditions=>{:company_id=>['@current_company.id']}, :order=>:name) do |t|
    t.column :name, :url=>{:action=>:cash}
    t.column :nature_label
    t.column :name, :through=>:currency
    t.column :number, :through=>:account, :url=>{:action=>:account}
    t.column :name, :through=>:journal, :url=>{:action=>:journal}
    t.action :cash_update
    t.action :cash_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  # lists all the cashes with the mainly characteristics. 
  def cashes
  end

  create_kame(:cash_deposits, :model=>:deposits, :conditions=>{:company_id=>['@current_company.id'], :cash_id=>['session[:current_cash_id]']}, :order=>"created_on DESC") do |t|
    t.column :number, :url=>{:controller=>:management, :action=>:deposit}
    t.column :created_on
    t.column :payments_count
    t.column :amount
    t.column :name, :through=>:mode
    t.column :comment
  end

  create_kame(:cash_bank_statements, :model=>:bank_statements, :conditions=>{:company_id=>['@current_company.id'], :cash_id=>['session[:current_cash_id]']}, :order=>"started_on DESC") do |t|
    t.column :number, :url=>{:action=>:bank_statement}
    t.column :started_on
    t.column :stopped_on
    t.column :credit
    t.column :debit
  end

  def cash
    return unless @cash = find_and_check(:cash)
    session[:current_cash_id] = @cash.id
    t3e @cash.attributes.merge(:nature_label=>@cash.nature_label)
  end

  # this method creates a cash with a form.
  def cash_create
    if request.xhr? and params[:mode] == "accountancy"
      @cash = Cash.new(params[:cash])
      render :partial=>'cash_accountancy_form', :locals=>{:nature=>params[:nature]}
    elsif request.post? 
      @cash = Cash.new(params[:cash])
      @cash.company_id = @current_company.id
      @cash.entity_id = session[:entity_id] 
      return if save_and_redirect(@cash)
    else
      @cash = Cash.new(:mode=>"bban", :nature=>"bank_account")
      session[:entity_id] = params[:entity_id]||@current_company.entity_id
      @valid_account = @current_company.accounts.empty?
      @valid_journal = @current_company.journals.empty?  
    end
    render_form
  end

  # this method updates a cash with a form.
  def cash_update
    return unless @cash = find_and_check(:cash)
    if request.post? or request.put?
      @cash.attributes = params[:cash]
      return if save_and_redirect(@cash)
    end
    t3e @cash.attributes
    render_form
  end
  
  # this method deletes a cash.
  def cash_delete
    return unless @cash = find_and_check(:cash)
    @cash.destroy if request.delete? and @cash.destroyable?
    redirect_to :action => :cashes
  end

  create_kame(:cash_transfers, :conditions=>["company_id = ? ", ['@current_company.id']]) do |t|
    t.column :number, :url=>{:action=>:cash_transfer}
    t.column :emitter_amount
    t.column :name, :through=>:emitter_currency
    t.column :name, :through=>:emitter_cash, :url=>{:action=>:cash}
    t.column :receiver_amount
    t.column :name, :through=>:receiver_currency
    t.column :name, :through=>:receiver_cash, :url=>{:action=>:cash}
    t.column :created_on
    t.action :cash_transfer_update
    t.action :cash_transfer_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  def cash_transfers
  end

  manage :cash_transfers

  def cash_transfer
    return unless @cash_transfer = find_and_check(:cash_transfer)
    t3e @cash_transfer.attributes
  end



  def self.accounts_conditions
    code  = "c=['company_id = ? AND number LIKE ?', @current_company.id, session[:account_prefix]]\n"
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
    if request.post?
      session[:used_accounts] = params[:used_accounts]
      session[:started_on] = params[:started_on]
      session[:stopped_on] = params[:stopped_on]
    end
    # if params[:clean]
    #   for account in @current_company.accounts.find(:all, :order=>"number DESC")
    #     account.save
    #   end
    # end
    params[:used_accounts] = session[:used_accounts]
    params[:started_on] = session[:started_on]
    params[:stopped_on] = session[:stopped_on]
  end

  def accounts_load
    if request.post?
      locale, name = params[:list].split(".")
      @current_company.load_accounts(name, locale)
    end
    redirect_to :action=>:accounts
  end

  manage :accounts, :number=>"params[:number]"

  create_kame(:account_journal_entry_lines, :model=>:journal_entry_lines, :conditions=>["company_id = ? AND account_id = ?", ['@current_company.id'], ['session[:current_account_id]']], :order=>"entry_id DESC, position") do |t|
    t.column :name, :through=>:journal, :url=>{:action=>:journal}
    t.column :number, :through=>:entry, :url=>{:action=>:journal_entry}
    t.column :printed_on, :through=>:entry, :datatype=>:date, :label=>:column
    t.column :name
    t.column :draft
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


  create_kame(:unlettered_journal_entry_lines, :model=>:journal_entry_lines, :joins=>"JOIN #{Account.table_name} AS accounts ON (account_id=accounts.id)", :conditions=>["#{JournalEntryLine.table_name}.company_id=? AND accounts.number LIKE ? AND LENGTH(TRIM(COALESCE(letter, ''))) = 0", ['@current_company.id'], ["session[:current_account_prefix].to_s+'%'"]], :order=>"letter DESC, accounts.number, credit") do |t|
    t.column :number, :through=>:account, :url=>{:action=>:account_letter}
    t.column :name, :through=>:account, :url=>{:action=>:account_letter}
    t.column :number, :through=>:entry
    t.column :name
    t.column :debit
    t.column :credit
  end

  # This method allows to make lettering for the client and supplier accounts.
  def lettering
    session[:current_lettering_mode] = params[:id] = params[:id] || session[:current_lettering_mode] || :clients
    session[:current_account_prefix] = @current_company.preference("accountancy.accounts.third_#{params[:id]}").value
  end


  # this method displays the array for make lettering.
  def account_letter
    return unless @account = find_and_check(:account)
    fy = @current_company.current_financial_year
    params[:stopped_on] = (params[:stopped_on]||(fy ? fy.stopped_on : Date.today)).to_date
    params[:started_on] = (params[:started_on]||(fy ? fy.started_on : params[:stopped_on]-1.month+1.day)).to_date
    if request.post?
      if params[:journal_entry_line]
        journal_entry_lines = params[:journal_entry_line].collect{|k,v| ((v[:to_letter]=="1" and @current_company.journal_entry_lines.find_by_id(k)) ? k.to_i : nil)}.compact
        @account.letter_entries(journal_entry_lines)
      else
        notify(:select_entries_to_letter_together, :warning, :now)
      end
    end
    @journal_entry_lines = @account.letterable_entry_lines(params[:started_on], params[:stopped_on])
    @letter = @account.new_letter
    t3e @account.attributes, :started_on=>params[:started_on], :stopped_on=>params[:stopped_on]
  end

  # this method displays the array for make lettering.
  def account_unletter
    return unless @account = find_and_check(:account)
    if request.post? and params[:letter]
      @account.unletter_entries(params[:letter])
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
    code += "c[0] += \" OR (#{JournalEntryLine.table_name}.draft = #{conn.quoted_true})\" if options[:draft] == '1'\n"
    code += "c[0] += \" OR (#{JournalEntryLine.table_name}.draft = #{conn.quoted_false} AND #{JournalEntryLine.table_name}.closed = #{conn.quoted_false})\" if options[:confirmed] == '1'\n"
    code += "c[0] += \" OR (#{JournalEntryLine.table_name}.closed = #{conn.quoted_true})\" if options[:closed] == '1'\n"
    code += "c[0] += \")\"\n"    
    # accounts
    code += "c[0] += ' AND ('+(session[:general_ledger][:accounts]||\"#{conn.quoted_false}\")+')'\n"
    # journals
    code += "c[0] += ' AND #{JournalEntryLine.table_name}.journal_id IN (?)'\n"    
    code += "c<<session[:general_ledger][:journals]\n"    
    code += "c\n"
    return code # .gsub(/\s*\n\s*/, ";")
  end

  create_kame(:general_ledger, :model=>:journal_entry_lines, :conditions=>general_ledger_conditions, :joins=>"JOIN #{JournalEntry.table_name} AS journal_entries ON (entry_id = journal_entries.id) JOIN #{Account.table_name} AS accounts ON (account_id = accounts.id)", :order=>"accounts.number, journal_entries.number, position") do |t|
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
          accounts += " OR SUBSTR(accounts.number, 1, #{max}) BETWEEN #{conn.quote(start.ljust(max, '0'))} AND #{conn.quote(finish.ljust(max, 'Z'))}"
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
    code = ""
    code += "c=['#{JournalEntry.table_name}.company_id=? "
    code += " AND #{JournalEntry.table_name}.journal_id IN (?) " unless options[:all_journals]
    code += " AND #{JournalEntry.table_name}.draft=? " if options[:draft]
    code += "', @current_company.id"
    code += ", session[:current_journal_id]" unless options[:all_journals]
    code += ", true" if options[:draft]
    code += "]\n"
    code += "start, finish = nil, nil\n"
    code += "if session[:journal_entry_mode]=='automatic'\n"
    code += "  start, finish = session[:journal_entry_period].split('_')[0..1]\n"
    code += "else\n"
    code += "  start, finish = session[:journal_entry_start], session[:journal_entry_finish]\n"
    code += "end\n"
    code += "if (start.to_date rescue nil)\n"
    code += "  c[0]+=' AND #{JournalEntry.table_name}.printed_on>=?'\n"
    code += "  c<<start.to_date\n"
    code += "end\n"
    code += "if (finish.to_date rescue nil)\n"
    code += "  c[0]+=' AND #{JournalEntry.table_name}.printed_on<=?'\n"
    code += "  c<<finish.to_date\n"
    code += "end\n"
    code += "c\n"
    return code.gsub(/\s*\n\s*/, ";")
  end

  create_kame(:journal_entry_lines, :conditions=>journal_entries_conditions, :joins=>"JOIN #{JournalEntry.table_name} ON (entry_id = #{JournalEntry.table_name}.id)", :line_class=>"(RECORD.last\? ? 'last-entry' : '')", :order=>"entry_id DESC, position") do |t|
    t.column :number, :through=>:entry, :url=>{:action=>:journal_entry}
    t.column :printed_on, :through=>:entry, :datatype=>:date
    t.column :number, :through=>:account, :url=>{:action=>:account}
    t.column :name, :through=>:account, :url=>{:action=>:account}
    t.column :name
    t.column :draft
    t.column :debit
    t.column :credit
  end
  
  create_kame(:journal_entries, :conditions=>journal_entries_conditions, :order=>"created_at DESC") do |t|
    t.column :number, :url=>{:action=>:journal_entry}
    t.column :printed_on
    t.column :draft
    t.column :debit
    t.column :credit
    t.action :journal_entry_update, :if=>'RECORD.updateable? '
    t.action :journal_entry_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.destroyable\?"
  end
  
  create_kame(:journal_mixed, :model=>:journal_entries, :conditions=>journal_entries_conditions, :children=>:lines, :order=>"created_at DESC", :per_page=>10) do |t|
    t.column :number, :url=>{:action=>:journal_entry}, :children=>:name
    t.column :printed_on, :datatype=>:date, :children=>false
    # t.column :label, :through=>:account, :url=>{:action=>:account}
    t.column :draft
    t.column :debit
    t.column :credit
    t.action :journal_entry_update, :if=>'RECORD.updateable? '
    t.action :journal_entry_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.destroyable\?"
  end

  create_kame(:journal_draft_entry_lines, :model=>:journal_entry_lines, :conditions=>journal_entries_conditions(:draft=>true), :joins=>"JOIN #{JournalEntry.table_name} ON (entry_id = #{JournalEntry.table_name}.id)", :order=>"entry_id DESC, position") do |t|
    t.column :number, :through=>:entry, :url=>{:action=>:journal_entry}
    t.column :printed_on, :through=>:entry, :datatype=>:date
    t.column :number, :through=>:account, :url=>{:action=>:account}
    t.column :name, :through=>:account, :url=>{:action=>:account}
    t.column :name
    t.column :draft
    t.column :debit
    t.column :credit
  end  


  def journal_filter()
    fy = @current_company.current_financial_year
    session[:journal_entry_period] = params[:period] = params[:period]||(fy ? fy.started_on.to_s+"_"+fy.stopped_on.to_s : nil)
    session[:journal_entry_mode]   = params[:mode]   = params[:mode]||"automatic"
    session[:journal_entry_start]  = params[:start]  = params[:start]||(fy ? fy.started_on : Date.today)
    session[:journal_entry_finish] = params[:finish] = params[:finish]||(fy ? fy.stopped_on : Date.today)
    if action_name == "draft_entry_lines"
      journals = []
      for name, value in params.select{|k, v| k.to_s.match(/^journal_\d+$/) and v.to_i == 1}
        journals << @current_company.journals.find(name.split(/\_/)[-1].to_i).id rescue nil
      end
      session[:current_journal_id] = journals.compact
    end
  end


  @@journal_views = ["entry_lines", "entries", "mixed", "draft_entry_lines"]
  cattr_reader :journal_views

  def journal
    return unless @journal = find_and_check(:journal)
    journal_filter
    @journal_views
    session[:current_journal_id] = @journal.id
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


  create_kame(:draft_entry_lines, :model=>:journal_entry_lines, :conditions=>journal_entries_conditions(:draft=>true), :joins=>"JOIN #{JournalEntry.table_name} ON (entry_id = #{JournalEntry.table_name}.id)", :order=>"entry_id DESC, position") do |t|
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
  def draft_entry_lines
    journal_filter
    if request.post? and params[:validate]
      conditions = nil
      begin
        conditions = eval(self.class.journal_entries_conditions(:draft=>true))
        journal_entries = @current_company.journal_entries.find(:all, :conditions=>conditions)
        undone = 0
        for entry in journal_entries
          entry.draft_mode = false
          entry.save
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
      @journal_entry_lines = (params[:entries]||{}).values
      if @journal_entry.save_with_lines(@journal_entry_lines)
        notify(:journal_entry_has_been_saved, :success, :number=>@journal_entry.number)
        redirect_to :action=>:journal_entry_create, :journal_id=>@journal.id, :draft_mode=>(1 if @journal_entry.draft_mode)
      end
    else
      @journal_entry.printed_on = @journal_entry.created_on = Date.today
      @journal_entry.number = @journal.next_number
      @journal_entry.draft_mode = true if params[:draft_mode].to_i == 1
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
    t.column :name, :through=>:cash, :url=>{:action=>:cash}
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
      redirect_to :action=>:cash_create
      return
    end
    notify(:x_unpointed_journal_entry_lines, :now, :count=>@current_company.journal_entry_lines.count(:conditions=>["bank_statement_id IS NULL and account_id IN (?)", cashes.collect{|ba| ba.account_id}]))
  end




  create_kame(:bank_statement_entries, :model =>:journal_entry_lines, :conditions=>{:company_id=>['@current_company.id'], :bank_statement_id=>['session[:current_bank_statement_id]']}, :order=>"entry_id") do |t|
    t.column :name, :through=>:journal, :url=>{:action=>:journal}
    t.column :number, :through=>:entry, :url=>{:action=>:journal_entry}
    t.column :created_on, :through=>:entry, :datatype=>:date, :label=>:column
    t.column :name
    t.column :number, :through=>:account, :url=>{:action=>:account}
    t.column :debit
    t.column :credit
  end

  # displays in details the statement choosen with its mainly characteristics.
  def bank_statement
    return unless @bank_statement = find_and_check(:bank_statement)
    session[:current_bank_statement_id] = @bank_statement.id
    t3e @bank_statement.attributes
  end
  
  manage :bank_statements, :cash_id=>"params[:cash_id]", :started_on=>"@current_company.cashes.find(params[:cash_id]).last_bank_statement.stopped_on+1 rescue (Date.today-1.month-2.days)", :stopped_on=>"@current_company.cashes.find(params[:cash_id]).last_bank_statement.stopped_on>>1 rescue (Date.today-2.days)", :redirect_to=>'{:action => :bank_statement_point, :id =>"id"}'


  # This method displays the list of entries recording to the bank account for the given statement.
  def bank_statement_point
    session[:statement] = params[:id]  if request.get? 
    return unless @bank_statement = find_and_check(:bank_statement)
    if request.post?
      # raise Exception.new(params[:journal_entry_line].inspect)
      @bank_statement.journal_entry_lines.clear
      @bank_statement.journal_entry_line_ids = params[:journal_entry_line].select{|k, v| v[:checked]=="1" and @current_company.journal_entry_lines.find_by_id(k)}.collect{|k, v| k.to_i}
      if @bank_statement.save
        redirect_to :action=>:bank_statements
        return
      end
    end
    @journal_entry_lines = @bank_statement.eligible_entry_lines
    unless @journal_entry_lines.size > 0
      notify(:need_entries_to_point, :warning)
      redirect_to :action=>:bank_statements
    end    
    t3e :number => @bank_statement.number, :cash => @bank_statement.cash.name
  end




  
  create_kame(:taxes, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :amount, :precision=>3
    t.column :nature_label
    t.column :included
    t.column :reductible
    t.column :label, :through=>:paid_account, :url=>{:action=>:account}
    t.column :label, :through=>:collected_account, :url=>{:action=>:account}
    t.action :tax_update
    t.action :tax_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  def taxes
  end
  
  manage :taxes, :nature=>":percent"


  #
  create_kame(:tax_declarations, :conditions=>{:company_id=>['@current_company.id']}, :order=>:declared_on) do |t|
    t.column :nature
    t.column :address
    t.column :declared_on, :datatype=>:date
    t.column :paid_on, :datatype=>:date
    t.column :amount
    t.action :tax_declaration, :image => :show
    t.action :tax_declaration_update #, :if => '!RECORD.submitted?'  
    t.action :tax_declaration_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete #, :if => '!RECORD.submitted?'
  end
  
  # this method lists all the tax declarations.
  def tax_declarations
    @journals  =  @current_company.journals.find(:all, :conditions => ["nature = ? OR nature = ?", :sale.to_s,  :purchase.to_s])
    
    if @journals.nil?
      notify(:need_journal_to_manage_tax_declaration, :now)
      redirect_to :action=>:journal_create
      return
    else
      @journals.each do |journal|
        unless journal.closable?(Date.today)
          notify(:need_balanced_journal_to_tax_declaration)
          # redirect_to :action=>:entries
          return
        end
      end

    end

  end




  # this method displays the tax declaration in details.
  def tax_declaration
    return unless find_and_check(:tax_declaration)
    
    # last vat declaration for read the excedent VAT
    # if ["simplified"].include? @tax_declaration.nature
    #       started_on = @tax_declaration.started_on.years_ago 1
    #     else
    #       if ["monthly"].include? @tax_declaration.period
    #         started_on = @tax_declaration.started_on.months_ago 1.beginning_of_month
    #       else
    #         started_on = @tax_declaration.started_on.months_ago 3.beginning_of_month
    #       end
    #     end
    #     @last_tax_declaration = @current_company.tax_declarations.find(:last, :conditions=> ["started_on =  ? and stopped_on = ?", started_on, (@tax_declaration.started_on-1)])
    
    
    # datas for vat collected 
    @normal_vat_collected_amount = {}
    @normal_not_collected_amount = {}
    @normal_vat_collected_amount[:national] = @current_company.filtering_entries(:credit, ['445713*'], [@tax_declaration.started_on, @tax_declaration.stopped_on])
    @normal_not_collected_amount[:national] = @current_company.filtering_entries(:credit, ['707003'], [@tax_declaration.started_on, @tax_declaration.stopped_on])
    
    @normal_vat_collected_amount[:international] = @current_company.filtering_entries(:credit, ['445714*'], [@tax_declaration.started_on, @tax_declaration.stopped_on])
    @normal_not_collected_amount[:international] = @current_company.filtering_entries(:credit, ['707004'], [@tax_declaration.started_on, @tax_declaration.stopped_on])

    @vat_paid_and_payback_amount = @current_company.filtering_entries(:credit, ['445660'], [@tax_declaration.started_on, @tax_declaration.stopped_on])
    
    @reduce_vat_collected_amount = {}
    @reduce_not_collected_amount = {}
    @reduce_vat_collected_amount[:national] = @current_company.filtering_entries(:credit, ['445712*'], [@tax_declaration.started_on, @tax_declaration.stopped_on])
    @reduce_not_collected_amount[:national] = @current_company.filtering_entries(:credit, ['707002'], [@tax_declaration.started_on, @tax_declaration.stopped_on])

    @reduce_vat_collected_amount[:international] = @current_company.filtering_entries(:credit, ['445711*'], [@tax_declaration.started_on, @tax_declaration.stopped_on])
    @reduce_not_collected_amount[:international] = @current_company.filtering_entries(:credit, ['707001'], [@tax_declaration.started_on, @tax_declaration.stopped_on])



    # assessable operations 
    
    # @vat_acquisitions_amount = @current_company.filtering_entries(:credit, ['4452*'], [@tax_declaration.period_begin, @tax_declaration.period_end]) 
    

    # datas for vat paid.
    @vat_deductible_fixed_amount = @current_company.filtering_entries(:debit, ['445620*'], [@tax_declaration.started_on, @tax_declaration.stopped_on])
    @vat_deductible_services_amount = @current_company.filtering_entries(:debit, ['445660*'], [@tax_declaration.started_on, @tax_declaration.stopped_on])
    @vat_deductible_others_amount = @current_company.filtering_entries(:debit, ['44563*'], [@tax_declaration.started_on, @tax_declaration.stopped_on])
    @vat_deductible_left_balance_amount = @current_company.filtering_entries(:debit, ['44567*'], [@tax_declaration.started_on, @tax_declaration.stopped_on])

    # downpayment amount
    if ["simplified"].include? @tax_declaration.nature
      @downpayment_amount = @current_company.filtering_entries(:debit, ['44581*'], [@tax_declaration.started_on, @tax_declaration.stopped_on])
      
      #  others operations for vat collected
      # @sales_fixed_amount = @current_company.filtering_entries(:credit, ['775*'], [@tax_declaration.period_begin, @period_end])
      # @vat_sales_fixed_amount = @current_company.filtering_entries(:debit, ['44551*'], [@tax_declaration.period_begin, @period_end])

      # @oneself_deliveries_amount = @current_company.filtering_entries(:credit, ['772000*'], [@tax_declaration.period_begin, @period_end])
    end

    # payback of vat credits.
    @vat_payback_amount = @current_company.filtering_entries(:debit, ['44583*'], [@tax_declaration.started_on, @tax_declaration.stopped_on])

    t3e :nature => tc(@tax_declaration.nature), :started_on => @tax_declaration.started_on, :stopped_on => @tax_declaration.stopped_on
  end
  


  # this method creates a tax declaration.
  def tax_declaration_create
    
    @financial_years = @current_company.financial_years.find(:all, :conditions => ["closed = 't'"])
    
    unless @financial_years.size > 0
      notify(:need_closed_financial_year_to_declaration)
      redirect_to :action=>:tax_declarations
      return
    end
    
    if request.post?
      started_on = params[:tax_declaration][:started_on]
      stopped_on = params[:tax_declaration][:stopped_on]
      params[:tax_declaration].delete(:period) 
      
      vat_acquisitions_amount = @current_company.filtering_entries(:credit, ['4452*'], [started_on, stopped_on]) 
      vat_collected_amount = @current_company.filtering_entries(:credit, ['44571*'], [started_on, stopped_on]) 
      vat_deductible_amount = @current_company.filtering_entries(:debit, ['4456*'], [started_on, stopped_on]) 
      vat_balance_amount = @current_company.filtering_entries(:debit, ['44567*'], [started_on, stopped_on]) 
      vat_assimilated_amount = @current_company.filtering_entries(:credit, ['447*'], [started_on, stopped_on]) 

      journal_od = @current_company.journals.find(:last, :conditions=>["nature = ? and closed_on < ?", :various.to_s, Date.today.to_s])

      #      raise Exception.new(params.inspect)
      @current_company.journals.create!(:nature=>"various", :name=>tc(:various), :currency_id=>@current_company.currencies(:first), :code=>"OD", :closed_on=>Date.today) if journal_od.nil?
      
      
      
      @tax_declaration = TaxDeclaration.new(params[:tax_declaration].merge!({:collected_amount=>vat_collected_amount, :paid_amount=>vat_deductible_amount, :balance_amount=>vat_balance_amount, :assimilated_taxes_amount=>vat_assimilated_amount, :acquisition_amount=>vat_acquisitions_amount, :started_on=>started_on, :stopped_on=>stopped_on}))
      @tax_declaration.company_id = @current_company.id
      return if save_and_redirect(@tax_declaration)
      
    else
      @tax_declaration = TaxDeclaration.new

      if @tax_declaration.new_record?
        last_declaration = @current_company.tax_declarations.find(:last, :select=>"DISTINCT id, started_on, stopped_on, nature")
        if last_declaration.nil?
          @tax_declaration.nature = "normal"
          last_financial_year = @current_company.financial_years.find(:last, :conditions=>{:closed => true})
          @tax_declaration.started_on = last_financial_year.started_on
          @tax_declaration.stopped_on = last_financial_year.started_on.end_of_month
        else
          @tax_declaration.nature = last_declaration.nature
          @tax_declaration.started_on = last_declaration.stopped_on+1
          @tax_declaration.stopped_on = @tax_declaration.started_on+(last_declaration.stopped_on-last_declaration.started_on)-2          
        end
        @tax_declaration.stopped_on = params[:stopped_on].to_s if params.include? :stopped_on and params[:stopped_on].blank?
      end
      
    end       
    
    render_form
  end


  # this method updates a tax declaration.
  def tax_declaration_update
    return unless find_and_check(:tax_declaration)
    render_form
  end


  # this method computes the end of tax declaration depending the period choosen.
  def tax_declaration_period_search
    if request.xhr?
      started_on =  params["started_on"].to_date
      
      @stopped_on=started_on.end_of_month if (["monthly"].include? params["period"])
      @stopped_on=(started_on.months_since 2).end_of_month.to_s if (["quarterly"].include? params["period"])
      @stopped_on=(started_on.months_since 11).end_of_month if (["yearly"].include? params["period"])
      @stopped_on='' if (["other"].include? params["period"])
      
      render :action=>"tax_declaration_period_search.rjs"

    end
  end
  

  # this method deletes a tax declaration.
  def tax_declaration_delete
    if request.post? or request.delete?
      @tax_declaration = TaxDeclaration.find_by_id_and_company_id(params[:id], @current_company.id) 
      TaxDeclaration.destroy @tax_declaration
    end    
    redirect_to :action => "tax_declarations"
  end

end



