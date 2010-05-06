# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2009-2010 Brice Texier, Thibaud Mérigon
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
  dyli(:account_collected, ["number:X%", :name], :model=>:account, :conditions => {:company_id=>['@current_company.id']})
  dyli(:account_paid, ["number:X%", :name], :model=>:account, :conditions => {:company_id=>['@current_company.id']})
  
  # 
  def index
    @entries = @current_company.journal_entries
  end

  # this method displays the form to choose the journal and financialyear.
  def accountize
    params[:finish_accountization_on] = (params[:finish_accountization_on]||Date.today).to_date rescue Date.today

    if request.get?
      notify(:accountizing_works_only_with_sales_invoices, :information, :now)
      @step = 1
    elsif request.put?
      @step = 2
    elsif request.post?
      @step = 3
    end

    if @step >= 2
      session[:finish_accountization_on] = params[:finish_accountization_on]
      @invoices = @current_company.invoices.find(:all, :conditions=>["accounted_at IS NULL and amount != 0 AND CAST(created_on AS DATE) <= ?", session[:finish_accountization_on]])

      if @step == 3
        no_draft = true # (params[:dont_save_in_draft] == "1" ? true : false)
        for invoice in @invoices
          invoice.to_accountancy(:no_draft=>no_draft)
        end
        
        #       # all the purchase_orders are accountized.
        #       @purchase_orders = @current_company.purchase_orders.find(:all, :conditions=>["accounted_at IS NULL AND created_on < ? ", session[:limit_period].to_s], :order=>"created_on DESC")                                                         
        #       @purchase_orders.each do |purchase_order|
        #         purchase_order.to_accountancy
        #       end
        
        #       #      # all the transfers are accountized.
        #       @transfers = @current_company.transfers.find(:all, :conditions=>["accounted_at IS NULL AND created_on < ? ", session[:limit_period].to_s],:order=>"created_on DESC")
        #       @transfers.each do |transfer|
        #         transfer.to_accountancy
        #       end
        
        #       # all the payments are comptabilized if they have been embanked or not.  
        #       #   join = "inner join embankments e on e.id=payments.embankment_id" unless session[:cashed_payments]
        #       #       @payments = @current_company.payments.find(:all, :conditions=>["payments.created_on < ? and payments.accounted_at IS NULL and payments.amount!=0", session[:limit_period].to_s], :joins=>join||nil, :order=>"created_on DESC", :limit=>100)    
        #       #       @payments.each do |payment|
        #       #         payment.to_accountancy
        #       #       end
        
        #       #       # the sale_orders are comptabilized if the matching payments and invoices have been already accountized.  
        #       #       @sale_orders = @current_company.sale_orders.find(:all, :conditions=>["sale_orders.created_on < ? and sale_orders.accounted_at IS NULL and p.accounted_at IS NOT NULL and i.accounted_at IS NOT NULL", session[:limit_period].to_s], :joins=>"inner join payment_parts part on part.expense_id=sale_orders.id and part.expense_type='#{SaleOrder.name}' inner join payments p on p.id=part.payment_id inner join invoices i on i.id=part.invoice_id",:order=>"created_on DESC", :limit=>100)    
        #       #       @sale_orders.each do |sale_order|
        #       #         sale_order.to_accountancy 
        #       #       end

        notify(:accountizing_is_finished, :success)
        redirect_to :action=>:accountize
        # if no_draft
        #   redirect_to :action=>:accountize
        # else
        #   redirect_to :action=>:draft_entries
        # end
      end
    end
    

  end
  




  # dyta(:draft_entries, :model=>:journal_entries, :conditions=>{:company_id=>['@current_company.id'], :draft=>true}, :order=>:record_id, :line_class=>'RECORD.mode') do |t|
  #   t.column :journal_name, :label=>'Journal'
  #   t.column :resource, :label=>'Type'
  #   t.column :resource_id, :label=>'Id', :through=>:record
  #   t.column :number, :label=>"Numéro", :through=>:record
  #   t.column :created_on, :label=>"Créée le", :through=>:record, :datatype=>:date
  #   t.column :printed_on, :label=>"Saisie le", :through=>:record, :datatype=>:date
  #   t.column :name
  #   t.column :number, :label=>"Compte" , :through=>:account
  #   t.column :debit
  #   t.column :credit
  #   t.action :entry_update, :if => '!RECORD.close?', :url=>{:action=>:entry_update, :accountize=>true}   
  #   t.action :entry_delete, :method => :post, :confirm=>:are_you_sure, :if => '!RECORD.close? and !RECORD.letter?'
  # end
  

  # #this method lists all the entries generated in draft mode.
  # def draft_entries
  # end
  


  dyta(:bank_accounts, :conditions=>{:company_id=>['@current_company.id']}, :order=>:name) do |t|
    t.column :name
    t.column :iban_label
    t.column :name, :through=>:journal, :url=>{:action=>:journal}
    t.column :name, :through=>:currency
    t.column :number, :through=>:account
    t.action :bank_account_update
    t.action :bank_account_delete, :method=>:delete, :confirm=>:are_you_sure
  end
  


  # lists all the bank_accounts with the mainly characteristics. 
  def bank_accounts
  end

  # this method creates a bank_account with a form.
  def bank_account_create
    if request.post? 
      @bank_account = BankAccount.new(params[:bank_account])
      @bank_account.company_id = @current_company.id
      @bank_account.entity_id = session[:entity_id] 
      return if save_and_redirect(@bank_account)
    else
      @bank_account = BankAccount.new(:mode=>"bban")
      session[:entity_id] = params[:entity_id]||@current_company.entity_id
      @valid_account = @current_company.accounts.empty?
      @valid_journal = @current_company.journals.empty?  
    end
    render_form
  end

  # this method updates a bank_account with a form.
  def bank_account_update
    return unless @bank_account = find_and_check(:bank_account)
    if request.post? or request.put?
      @bank_account.attributes = params[:bank_account]
      return if save_and_redirect(@bank_account)
    end
    render_form
  end
  
  # this method deletes a bank_account.
  def bank_account_delete
    return unless @bank_account = find_and_check(:bank_account)
    if request.post? or request.delete?
      if @bank_account.statements.size > 0
        @bank_account.update_attribute(:deleted, true)
      else
        BankAccount.destroy @bank_account
      end
    end
    redirect_to :action => :bank_accounts
  end



  def self.accounts_conditions
    code  = "c=['company_id = ? AND number LIKE ?', @current_company.id, session[:account_prefix]]\n"
    code += "if (session[:used_accounts])\n"
    code += "  c[0]+=' AND id IN (SELECT account_id FROM journal_entries JOIN journal_records ON (record_id=journal_records.id) WHERE created_on BETWEEN ? AND ? AND journal_entries.company_id = ?)'\n"
    code += "  c+=[(params[:started_on].to_date rescue Date.civil(1901,1,1)), (params[:stopped_on].to_date rescue Date.civil(1901,1,1)), @current_company.id]\n"
    code += "end\n"
    code += "c"
    return code
  end

  dyta(:accounts, :conditions=>accounts_conditions, :order=>"number ASC") do |t|
    t.column :number, :url=>{:action=>:account}
    t.column :name, :url=>{:action=>:account}
    t.action :account_update
    t.action :account_delete, :method=>:delete, :confirm=>:are_you_sure
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

  manage :accounts, :number=>"params[:number]"

  dyta(:account_journal_entries, :model=>:journal_entries, :conditions=>["company_id = ? AND account_id = ?", ['@current_company.id'], ['session[:account_id]']], :order=>"created_at DESC") do |t|
    t.column :name, :through=>:journal, :url=>{:action=>:journal}
    t.column :number, :through=>:record, :url=>{:action=>:journal_record}
    t.column :created_on, :through=>:record, :datatype=>:date, :label=>JournalRecord.human_attribute_name("created_on")
    t.column :name
    t.column :debit
    t.column :credit
  end

  dyta(:account_children, :model=>:accounts, :conditions=>["company_id = ? AND parent_id = ?", ['@current_company.id'], ['session[:account_id]']], :order=>"number ASC") do |t|
    t.column :number, :url=>{:action=>:account}
    t.column :name, :url=>{:action=>:account}
    t.action :account_update
    t.action :account_delete, :method=>:delete, :confirm=>:are_you_sure
  end

  def account
    return unless @account = find_and_check(:account)
    session[:account_id] = @account.id
    t3e @account.attributes
  end


  # This method allows to make lettering for the client and supplier accounts.
  def lettering
    clients_account = @current_company.parameter('accountancy.third_accounts.clients').value.to_s
    suppliers_account = @current_company.parameter('accountancy.third_accounts.suppliers').value.to_s
    
    Account.create!(:name=>"Clients", :number=>clients_account, :company_id=>@current_company.id) unless @current_company.accounts.exists?(:number=>clients_account)
    Account.create!(:name=>"Fournisseurs", :number=>suppliers_account, :company_id=>@current_company.id) unless @current_company.accounts.exists?(:number=>suppliers_account)
    @accounts_client=@current_company.accounts.find(:all, :conditions => ["number LIKE ?", clients_account+'%'])
    @accounts_supplier=@current_company.accounts.find(:all, :conditions=>["number LIKE ?", suppliers_account+'%'])

    if request.post?
      @account = @current_company.accounts.find(params[:account_client_id], params[:account_supplier_id])
      redirect_to :action => :account_letter, :id => @account.id
    end
  end


  # this method displays the array for make lettering.
  def account_letter
    return unless @account = find_and_check(:account)
    params[:stopped_on] = (params[:stopped_on]||Date.today).to_date
    params[:started_on] = (params[:started_on]||params[:stopped_on]-1.month+1.day).to_date
    if request.post?
      if params[:journal_entry]
        journal_entries = params[:journal_entry].collect{|k,v| ((v[:to_letter]=="1" and @current_company.journal_entries.find_by_id(k)) ? k.to_i : nil)}.compact
        @account.letter_entries(journal_entries)
      else
        notify(:select_entries_to_letter_together, :warning, :now)
      end
    end
    @journal_entries = @account.letterable_entries(params[:started_on], params[:stopped_on])
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
      redirect_to params.merge(:action=>:print, :controller=>:company)
    end
    @document_template ||= @document_templates[0]
  end

  # PRINTS=[[:balance, {:partial=>"balance"}],
  #         [:general_ledger, {:partial=>"ledger"}],
  #         [:journal, {:partial=>"journal"}],
  #         [:journals, {:partial=>"journals"}],
  #         [:synthesis, {:partial=>"synthesis"}]]

  # # this method prepares the print of document.
  # def document_prepare
  #   @prints = PRINTS.select{|x| @current_company.document_templates.find_by_nature(x[0])}
  #   if request.post?
  #     session[:mode] = params[:print][:mode]
  #     redirect_to :action=>:document_print
  #   end
  # end
  
  # #  this method prints the document.
  # def document_print
  #   for print in PRINTS
  #     @print = print if print[0].to_s == session[:mode]
  #   end
  #   @financialyears =  @current_company.financialyears.find(:all, :order => :stopped_on)
  #   if @financialyears.nil?
  #     notify(:no_financialyear, :error)
  #     redirect_to :action => :document_prepare
  #     return      
  #   end
    
  #   @partial = 'print_'+@print[1][:partial]
  #   started_on = Date.today.year.to_s+"-01-01"
  #   stopped_on = Date.today.year.to_s+"-12-31"
    
  #   if request.post? 
  #     lines = []
  #     if @current_company.default_contact
  #       lines =  @current_company.default_contact.address.split(",").collect{ |x| x.strip}
  #       lines << @current_company.default_contact.phone if !@current_company.default_contact.phone.nil?
  #       lines << @current_company.code
  #     end
      
  #     sum = {:debit=> 0, :credit=> 0, :balance=> 0}
      
  #     if session[:mode] == "journals"
  #       entries = @current_company.records(params[:printed][:from], params[:printed][:to])
        
  #       if entries.size > 0
  #         entries.each do |entry|
  #           sum[:debit] += entry.debit
  #           sum[:credit] += entry.credit
  #         end
  #         sum[:balance] = sum[:debit] - sum[:credit]
  #       end
        
  #       journal_template = @current_company.document_templates.find(:first, :conditions =>{:name => "Journal général"})
  #       if journal_template.nil?
  #         notify(:no_template_journal, :error)
  #         redirect_to :action=>:document_print
  #         return
  #       end
        
  #       pdf, filename = journal_template.print(@current_company, params[:printed][:from],  params[:printed][:to], entries, sum)
  #       send_data pdf, :type=>Mime::PDF, :filename=>filename
  #     end
      
  #     if session[:mode] == "journal"
  #       journal = Journal.find_by_id_and_company_id(params[:printed][:name], @current_company.id)
  #       id = @current_company.journals.find(:first, :conditions => {:name => journal.name }).id
  #       entries = @current_company.records(params[:printed][:from], params[:printed][:to], id)
        
  #       if entries.size > 0
  #         entries.each do |entry|
  #           sum[:debit] += entry.debit
  #           sum[:credit] += entry.credit
  #         end
  #         sum[:balance] = sum[:debit] - sum[:credit]
  #       end
        
  #       journal_template = @current_company.document_templates.find(:first, :conditions=>["name like ?", '%Journal auxiliaire%'])
  #       if journal_template.nil?
  #         notify(:no_template_journal_by_id, :error)
  #         redirect_to :action=>:document_print
  #         return
  #       end

  #       pdf, filename = journal_template.print(journal, params[:printed][:from], params[:printed][:to], entries, sum)

  #       send_data pdf, :type=>Mime::PDF, :filename=>filename
  #     end
      
  #     if session[:mode] == "balance"
  #       accounts_balance = Account.balance(@current_company.id, params[:printed][:from], params[:printed][:to])
  #       accounts_balance.delete_if {|account| account[:credit].zero? and account[:debit].zero?}
        
  #       for account in accounts_balance
  #         sum[:debit] += account[:debit]
  #         sum[:credit] += account[:credit]
  #       end
  #       sum[:balance] = sum[:debit] - sum[:credit]
        
  #       balance_template = @current_company.document_templates.find(:first, :conditions =>{:name => "Balance"})
  #       if balance_template.nil?
  #         notify(:no_balance_template, :error)
  #         redirect_to :action=>:document_prepare
  #         return
  #       end
        
  #       pdf, filename = balance_template.print(@current_company, accounts_balance,  params[:printed][:from],  params[:printed][:to], sum)
        
  #       send_data pdf, :type=>Mime::PDF, :filename=>filename
        
  #     end

  #     if session[:mode] == "synthesis"
  #       @financialyear = Financialyear.find_by_id_and_company_id(params[:printed][:financialyear], @current_company.id)
  #       params[:printed][:name] = @financialyear.code
  #       params[:printed][:from] = @financialyear.started_on
  #       params[:printed][:to] = @financialyear.stopped_on
  #       @balance = Account.balance(@current_company.id, @financialyear.started_on, @financialyear.stopped_on)
        
  #       @balance.each do |account| 
  #         sum[:credit] += account[:credit] 
  #         sum[:debit] += account[:debit] 
  #       end
  #       sum[:balance] = sum[:debit] - sum[:credit]     
        
  #       @last_financialyear = @financialyear.previous(@current_company.id)
        
  #       if not @last_financialyear.nil?
  #         index = 0
  #         @previous_balance = Account.balance(@current_company.id, @last_financialyear.started_on, @last_financialyear.stopped_on)
  #         @previous_balance.each do |balance|
  #           @balance[index][:previous_debit]   = balance[:debit]
  #           @balance[index][:previous_credit]  = balance[:credit]
  #           @balance[index][:previous_balance] = balance[:balance]
  #           index+=1
  #         end
  #         session[:previous_financialyear] = true
  #       end
        
  #       #raise Exception.new lines.inspect
        
  #       session[:lines] = lines
  #       session[:printed] = params[:printed]
  #       session[:balance] = @balance
        
  #       redirect_to :action => :synthesis
  #     end
      
  #     if session[:mode] == "general_ledger"
  #       ledger = Account.ledger(@current_company.id, params[:printed][:from], params[:printed][:to])
        
  #       #raise Exception.new ledger.inspect
        
  #       ledger_template = @current_company.document_templates.find(:first, :conditions=>{:name=>"Grand livre"})

        
        
  #       pdf, filename = ledger_template.print(@current_company, ledger,  params[:printed][:from],  params[:printed][:to])
        
  #       send_data pdf, :type=>Mime::PDF, :filename=>filename
  #     end
      
  #   end

  #   @title = {:value=>::I18n.t("views.#{self.controller_name}.document_prepare.#{@print[0]}")}
  # end
  
  # # this method displays the income statement and the balance sheet.
  # def synthesis
  #   @lines = session[:lines]
  #   @printed = session[:printed]
  #   @balance = session[:balance]
  #   @result = 0
  #   @solde = 0
  #   if session[:previous_financialyear] == true
  #     @previous_solde = 0
  #     @previous_result = 0
  #   end
  #   @active_fixed_sum = 0
  #   @active_current_sum = 0
  #   @passive_capital_sum = 0
  #   @passive_stock_sum = 0
  #   @passive_debt_sum = 0
  #   @previous_active_fixed_sum = 0
  #   @previous_active_current_sum = 0
  #   @previous_passive_capital_sum = 0
  #   @previous_passive_stock_sum = 0
  #   @previous_passive_debt_sum = 0
  #   @cost_sum = 0
  #   @finished_sum =  0
  #   @previous_active_sum = 0
  #   @previous_passive_sum = 0
  #   @previous_cost_sum = 0
  #   @previous_finished_sum = 0
    
  #   @balance.each do |account|
  #     @solde += account[:balance]
  #     @result = account[:balance] if account[:number].to_s.match /^12/
  #     @active_fixed_sum += account[:balance] if account[:number].to_s.match /^(20|21|22|23|26|27)/
  #     @active_current_sum += account[:balance] if account[:number].to_s.match /^(3|4|5)/ and account[:balance] >= 0
  #     @passive_capital_sum += account[:balance] if account[:number].to_s.match /^(1[^5])/
  #     @passive_stock_sum += account[:balance] if account[:number].to_s.match /^15/ 
  #     @passive_debt_sum += account[:balance] if account[:number].to_s.match /^4/ and account[:balance] < 0
  #     @cost_sum += account[:balance] if account[:number].to_s.match /^6/
  #     @finished_sum += account[:balance] if account[:number].to_s.match /^7/
  #     if session[:previous_financialyear] == true
  #       @previous_solde += account[:previous_balance] 
  #       @previous_result = account[:previous_balance] if account[:number].to_s.match /^12/
  #       @previous_active_fixed_sum += account[:previous_balance] if account[:number].to_s.match /^(20|21|22|23|26|27)/
  #       @previous_active_current_sum += account[:previous_balance] if account[:number].to_s.match /^(3|4|5)/ and account[:balance] >= 0
  #       @previous_passive_capital_sum += account[:previous_balance] if account[:number].to_s.match /^(1[^5])/
  #       @previous_passive_stock_sum += account[:previous_balance] if account[:number].to_s.match /^15/ 
  #       @previous_passive_debt_sum += account[:previous_balance] if account[:number].to_s.match /^4/ and account[:balance] < 0
  #       @previous_cost_sum += account[:previous_balance] if account[:number].to_s.match /^6/
  #       @previous_finished_sum += account[:previous_balance] if account[:number].to_s.match /^7/
  #     end
  #   end

  #   @title={:value=>"la période du "+@printed[:from].to_s+" au "+@printed[:to].to_s}
  # end

  # this method orders sale.
  #def order_sale
  # render(:xil=>"#{RAILS_ROOT}/app/views/prints/sale_order.xml",:key=>params[:id])
  #end
  
  dyta(:financialyears, :conditions=>{:company_id=>['@current_company.id']}, :order=>"started_on DESC") do |t|
    t.column :code, :url=>{:action=>:financialyear}
    t.column :closed
    t.column :started_on,:url=>{:action=>:financialyear}
    t.column :stopped_on,:url=>{:action=>:financialyear}
    t.action :financialyear_close, :if => '!RECORD.closed and RECORD.closable?'
    t.action :financialyear_update, :if => '!RECORD.closed'  
    t.action :financialyear_delete, :method => :post, :confirm=>:are_you_sure, :if => '!RECORD.closed'  
  end

  # lists all the bank_accounts with the mainly characteristics. 
  def financialyears
  end

  def financialyear
    return unless @financialyear = find_and_check(:financialyears)
    @financialyear.compute_balances
    t3e @financialyear.attributes
  end
  
  # this action creates a financialyear with a form.
  def financialyear_create
    if request.post? 
      @financialyear = Financialyear.new(params[:financialyear])
      @financialyear.company_id = @current_company.id
      return if save_and_redirect(@financialyear)
    else
      @financialyear = Financialyear.new
      f = @current_company.financialyears.find(:first, :order=>"stopped_on DESC")
      @financialyear.started_on = f.stopped_on+1.day unless f.nil?
      @financialyear.started_on ||= Date.today
      @financialyear.stopped_on = (@financialyear.started_on+1.year-1.day).end_of_month
      @financialyear.code = @financialyear.default_code
    end
    
    render_form
  end
  
  
  # this action updates a financialyear with a form.
  def financialyear_update
    return unless @financialyear = find_and_check(:financialyears)
    if request.post? or request.put?
      @financialyear.attributes = params[:financialyear]
      return if save_and_redirect(@financialyear)
    end
    t3e @financialyear.attributes
    render_form
  end
  
  # this action deletes a financialyear.
  def financialyear_delete
    return unless @financialyear = find_and_check(:financialyears)
    if request.post? or request.delete?
      Financialyear.destroy @financialyear unless @financialyear.records.size > 0 
    end
    redirect_to :action => :financialyears
  end
  
  
  # This method allows to close the financialyear.
  def financialyear_close
    if params[:id].nil?
      # We need an ID to close some financial year
      if financialyear = @current_company.closable_financialyear
        redirect_to :action=>:financialyear_close, :id=>financialyear.id
      else
        notify(:no_closable_financialyear, :information)
        redirect_to :action=>:financialyears
      end
    else
      # Launch close process
      return unless @financialyear = find_and_check(:financialyear)
      if request.post?
        params[:journal_id]=@current_company.journals.create!(:nature=>"renew").id if params[:journal_id]=="0"
        if @financialyear.close(params[:financialyear][:stopped_on].to_date, :renew_id=>params[:journal_id])
          notify(:closed_financialyears, :success)
          redirect_to(:action=>:financialyears)
        end
      else
        journal = @current_company.journals.find(:first, :conditions => {:nature => "renew", :deleted => false})
        params[:journal_id] = (journal ? journal.id : 0)
      end    
    end
  end

  dyta(:journals, :conditions=>{:company_id=>['@current_company.id']}, :order=>:code) do |t|
    t.column :name, :url=>{:action=>:journal}
    t.column :code, :url=>{:action=>:journal}
    t.column :nature_label
    t.column :name, :through=>:currency
    t.column :closed_on
    t.action :document_print, :url=>{:code=>:JOURNAL, :journal=>"RECORD.id"}
    t.action :journal_close, :if=>'RECORD.closable?(Date.today)', :image=>:unlock
    t.action :journal_reopen, :if=>"RECORD.reopenable\?", :image=>:lock
    t.action :journal_update
    t.action :journal_delete, :method=>:delete, :confirm=>:are_you_sure
  end
  

  # 
  def journals
  end

  def self.journal_records_conditions
    code = ""
    code += "c=['company_id=? AND journal_id=?', @current_company.id, session[:current_journal_id]]\n"
    code += "if (session[:journal_record_start].to_date rescue nil)\n"
    code += "  c[0]+=' AND created_on>=?'\n"
    code += "  c<<session[:journal_record_start].to_date\n"
    code += "end\n"
    code += "if (session[:journal_record_end].to_date rescue nil)\n"
    code += "  c[0]+=' AND created_on<=?'\n"
    code += "  c<<session[:journal_record_end].to_date\n"
    code += "end\n"
    code += "c\n"
    return code.gsub(/\s*\n\s*/, ";")
  end

  dyta(:journal_records, :conditions=>journal_records_conditions, :order=>"created_at DESC") do |t|
    t.column :number, :url=>{:action=>:journal_record}
    t.column :debit
    t.column :credit
    t.column :printed_on
    t.column :created_at
    t.action :journal_record_update, :if=>'!RECORD.closed? '
    t.action :journal_record_delete, :method=>:delete, :confirm=>:are_you_sure, :if=>'!RECORD.closed? '
  end
  

  def journal
    return unless @journal = find_and_check(:journal)
    session[:current_journal_id]   = @journal.id
    session[:journal_record_start] = params[:start]||Date.today-6
    session[:journal_record_end]   = params[:end]||Date.today
    t3e @journal.attributes
  end

  manage :journals, :nature=>"Journal.natures[0][1]"


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



  dyta(:journal_record_entries, :model=>:journal_entries, :conditions=>{:company_id=>['@current_company.id'], :record_id=>['session[:current_journal_record_id]']}) do |t|
    t.column :name
    t.column :number, :through=>:account, :url=>{:action=>:account}
    t.column :name, :through=>:account, :url=>{:action=>:account}
    t.column :letter
    t.column :number, :through=>:statement
    t.column :currency_debit
    t.column :currency_credit
  end


  def journal_record
    return unless @journal_record = find_and_check(:journal_record)
    session[:current_journal_record_id] = @journal_record.id
    t3e @journal_record.attributes
  end



  # Permits to write records and entries in journal
  def journal_record_create
    return unless @journal = find_and_check(:journal)  
    session[:current_journal_id] = @journal.id
    @journal_record = @journal.records.build(params[:journal_record])
    if request.post?
      @journal_entries = (params[:entries]||{}).values
      if @journal_record.save_with_entries(@journal_entries)
        notify(:journal_record_has_been_saved, :success, :number=>@journal_record.number)
        redirect_to :action=>:journal_record_create, :id=>@journal.id
      end
    else
      @journal_record.printed_on = @journal_record.created_on = Date.today
      @journal_record.number = @journal.last_number.succ
      @journal_entries = []
    end
    t3e @journal.attributes
    render_form
  end

  def journal_record_update
    return unless @journal_record = find_and_check(:journal_record)  
    @journal = @journal_record.journal
    if request.post?
      @journal_record.attributes = params[:journal_record]
      @journal_entries = (params[:entries]||{}).values
      if @journal_record.save_with_entries(@journal_entries)
        redirect_to_back
      end
    else
      @journal_entries = @journal_record.entries
    end
    t3e @journal_record.attributes
    render_form
  end


  def journal_entry_create
    @journal_entry = JournalEntry.new
    if request.xhr?
      render :partial=>"journal_entry_row_form", :object=>@journal_entry
    else
      redirect_to_back
    end
  end







  
  dyta(:bank_account_statements, :conditions=>{:company_id=>['@current_company.id']}, :order=>"started_on ASC") do |t|
    t.column :name, :through=>:bank_account
    t.column :number, :url=>{:action=>:bank_account_statement}
    t.column :started_on
    t.column :stopped_on
    t.column :debit
    t.column :credit
    t.action :bank_account_statement_point
    t.action :bank_account_statement_update
    t.action :bank_account_statement_delete, :method=>:delete, :confirm=>:are_you_sure
  end

  # lists all the statements in details for a precise account.
  def bank_account_statements  
    bank_accounts = @current_company.bank_accounts
    unless bank_accounts.size>0
      notify(:need_bank_account_to_record_statements)
      redirect_to :action=>:bank_account_create
      return
    end
    notify(:x_unpointed_journal_entries, :now, :count=>@current_company.journal_entries.count(:conditions=>["statement_id IS NULL and account_id IN (?)", bank_accounts.collect{|ba| ba.account_id}]))
  end




  dyta(:bank_account_statement_entries, :model =>:journal_entries, :conditions=>{:company_id=>['@current_company.id'], :statement_id=>['session[:current_bank_account_statement_id]']}, :order=>"record_id") do |t|
    t.column :name, :through=>:journal, :url=>{:action=>:journal}
    t.column :number, :through=>:record, :url=>{:action=>:journal_record}
    t.column :created_on, :through=>:record, :datatype=>:date, :label=>JournalRecord.human_attribute_name("created_on")
    t.column :name
    t.column :number, :through=>:account, :url=>{:action=>:account}
    t.column :debit
    t.column :credit
  end

  # displays in details the statement choosen with its mainly characteristics.
  def bank_account_statement
    return unless @bank_account_statement = find_and_check(:bank_account_statement)
    session[:current_bank_account_statement_id] = @bank_account_statement.id
    t3e @bank_account_statement.attributes
  end
  
  manage :bank_account_statements, :started_on=>"Date.today-1.month-2.days", :stopped_on=>"Date.today-2.days", :redirect_to=>'{:action => :bank_account_statement_point, :id =>"id"}'


  # This method displays the list of entries recording to the bank account for the given statement.
  def bank_account_statement_point
    session[:statement] = params[:id]  if request.get? 
    return unless @bank_account_statement = find_and_check(:bank_account_statement)
    if request.post?
      # raise Exception.new(params[:journal_entry].inspect)
      @bank_account_statement.entries.clear
      @bank_account_statement.entry_ids = params[:journal_entry].select{|k, v| v[:checked]=="1" and @current_company.journal_entries.find_by_id(k)}.collect{|k, v| k.to_i}
      if @bank_account_statement.save
        redirect_to :action=>:bank_account_statements
        return
      end
    end
    @journal_entries = @bank_account_statement.eligible_entries
    unless @journal_entries.size > 0
      notify(:need_entries_to_point, :warning)
      redirect_to :action=>:bank_account_statements
    end    
    t3e :number => @bank_account_statement.number, :bank_account => @bank_account_statement.bank_account.name
  end




  
  dyta(:taxes, :conditions=>{:company_id=>['@current_company.id'], :deleted=>false}) do |t|
    t.column :name
    t.column :amount, :precision=>3
    t.column :nature_label
    t.column :included
    t.column :reductible
    t.action :tax_update
    t.action :tax_delete, :method=>:delete, :confirm=>:are_you_sure
  end

  def taxes
  end
  
  manage :taxes, :nature=>":percent"


  # #
  # dyta(:tax_declarations, :conditions=>{:company_id=>['@current_company.id']}, :order=>:declared_on) do |t|
  #   t.column :nature, :label=>"Régime"
  #   t.column :address
  #   t.column :declared_on, :datatype=>:date
  #   t.column :paid_on, :datatype=>:date
  #   t.column :amount
  #   t.action :tax_declaration, :image => :show
  #   t.action :tax_declaration_update, :image => :update #:if => '!RECORD.submitted?'  
  #   t.action :tax_declaration_delete, :image => :delete,  :method => :post, :confirm=>:are_you_sure #, :if => '!RECORD.submitted?'
    
  # end
  
  # # this method lists all the tax declarations.
  # def tax_declarations
  #   @journals  =  @current_company.journals.find(:all, :conditions => ["nature = ? OR nature = ?", :sale.to_s,  :purchase.to_s])
    
  #   if @journals.nil?
  #     notify(:need_journal_to_record_tax_declaration, :now)
  #     redirect_to :action=>:journal_create
  #     return
  #   else
  #     @journals.each do |journal|
  #       unless journal.closable?(Date.today)
  #         notify(:need_balanced_journal_to_tax_declaration)
  #         # redirect_to :action=>:entries
  #         return
  #       end
  #     end

  #   end

  # end




  # # this method displays the tax declaration in details.
  # def tax_declaration
  #   @tax_declaration = @current_company.tax_declarations.find(params[:id])
    
  #   # last vat declaration for read the excedent VAT
  #   # if ["simplified"].include? @tax_declaration.nature
  #   #       started_on = @tax_declaration.started_on.years_ago 1
  #   #     else
  #   #       if ["monthly"].include? @tax_declaration.period
  #   #         started_on = @tax_declaration.started_on.months_ago 1.beginning_of_month
  #   #       else
  #   #         started_on = @tax_declaration.started_on.months_ago 3.beginning_of_month
  #   #       end
  #   #     end
  #   #     @last_tax_declaration = @current_company.tax_declarations.find(:last, :conditions=> ["started_on =  ? and stopped_on = ?", started_on, (@tax_declaration.started_on-1)])
    
    
  #   # datas for vat collected 
  #   @normal_vat_collected_amount = {}
  #   @normal_not_collected_amount = {}
  #   @normal_vat_collected_amount[:national] = @current_company.filtering_entries(:credit, ['445713*'], [@tax_declaration.started_on, @tax_declaration.stopped_on])
  #   @normal_not_collected_amount[:national] = @current_company.filtering_entries(:credit, ['707003'], [@tax_declaration.started_on, @tax_declaration.stopped_on])
    
  #   @normal_vat_collected_amount[:international] = @current_company.filtering_entries(:credit, ['445714*'], [@tax_declaration.started_on, @tax_declaration.stopped_on])
  #   @normal_not_collected_amount[:international] = @current_company.filtering_entries(:credit, ['707004'], [@tax_declaration.started_on, @tax_declaration.stopped_on])

  #   @vat_paid_and_payback_amount = @current_company.filtering_entries(:credit, ['445660'], [@tax_declaration.started_on, @tax_declaration.stopped_on])
    
  #   @reduce_vat_collected_amount = {}
  #   @reduce_not_collected_amount = {}
  #   @reduce_vat_collected_amount[:national] = @current_company.filtering_entries(:credit, ['445712*'], [@tax_declaration.started_on, @tax_declaration.stopped_on])
  #   @reduce_not_collected_amount[:national] = @current_company.filtering_entries(:credit, ['707002'], [@tax_declaration.started_on, @tax_declaration.stopped_on])

  #   @reduce_vat_collected_amount[:international] = @current_company.filtering_entries(:credit, ['445711*'], [@tax_declaration.started_on, @tax_declaration.stopped_on])
  #   @reduce_not_collected_amount[:international] = @current_company.filtering_entries(:credit, ['707001'], [@tax_declaration.started_on, @tax_declaration.stopped_on])



  #   # assessable operations 
    
  #   # @vat_acquisitions_amount = @current_company.filtering_entries(:credit, ['4452*'], [@tax_declaration.period_begin, @tax_declaration.period_end]) 
    

  #   # datas for vat paid.
  #   @vat_deductible_fixed_amount = @current_company.filtering_entries(:debit, ['445620*'], [@tax_declaration.started_on, @tax_declaration.stopped_on])
  #   @vat_deductible_services_amount = @current_company.filtering_entries(:debit, ['445660*'], [@tax_declaration.started_on, @tax_declaration.stopped_on])
  #   @vat_deductible_others_amount = @current_company.filtering_entries(:debit, ['44563*'], [@tax_declaration.started_on, @tax_declaration.stopped_on])
  #   @vat_deductible_left_balance_amount = @current_company.filtering_entries(:debit, ['44567*'], [@tax_declaration.started_on, @tax_declaration.stopped_on])

  #   # downpayment amount
  #   if ["simplified"].include? @tax_declaration.nature
  #     @downpayment_amount = @current_company.filtering_entries(:debit, ['44581*'], [@tax_declaration.started_on, @tax_declaration.stopped_on])
      
  #     #  others operations for vat collected
  #     # @sale_fixed_amount = @current_company.filtering_entries(:credit, ['775*'], [@tax_declaration.period_begin, @period_end])
  #     # @vat_sale_fixed_amount = @current_company.filtering_entries(:debit, ['44551*'], [@tax_declaration.period_begin, @period_end])

  #     # @oneself_deliveries_amount = @current_company.filtering_entries(:credit, ['772000*'], [@tax_declaration.period_begin, @period_end])
  #   end

  #   # payback of vat credits.
  #   @vat_payback_amount = @current_company.filtering_entries(:debit, ['44583*'], [@tax_declaration.started_on, @tax_declaration.stopped_on])

  #   @title = {:nature => tc(@tax_declaration.nature), :started_on => @tax_declaration.started_on, :stopped_on => @tax_declaration.stopped_on }
  # end
  


  # # this method creates a tax declaration.
  # def tax_declaration_create
    
  #   @financialyears = @current_company.financialyears.find(:all, :conditions => ["closed = 't'"])
    
  #   unless @financialyears.size > 0
  #     notify(:need_closed_financialyear_to_declaration)
  #     redirect_to :action=>:tax_declarations
  #     return
  #   end
    
  #   if request.post?
  #     started_on = params[:tax_declaration][:started_on]
  #     stopped_on = params[:tax_declaration][:stopped_on]
  #     params[:tax_declaration].delete(:period) 
      
  #     vat_acquisitions_amount = @current_company.filtering_entries(:credit, ['4452*'], [started_on, stopped_on]) 
  #     vat_collected_amount = @current_company.filtering_entries(:credit, ['44571*'], [started_on, stopped_on]) 
  #     vat_deductible_amount = @current_company.filtering_entries(:debit, ['4456*'], [started_on, stopped_on]) 
  #     vat_balance_amount = @current_company.filtering_entries(:debit, ['44567*'], [started_on, stopped_on]) 
  #     vat_assimilated_amount = @current_company.filtering_entries(:credit, ['447*'], [started_on, stopped_on]) 

  #     journal_od = @current_company.journals.find(:last, :conditions=>["nature = ? and closed_on < ?", :various.to_s, Date.today.to_s])

  #     #      raise Exception.new(params.inspect)
  #     @current_company.journals.create!(:nature=>"various", :name=>tc(:various), :currency_id=>@current_company.currencies(:first), :code=>"OD", :closed_on=>Date.today) if journal_od.nil?
      
      
      
  #     @tax_declaration = TaxDeclaration.new(params[:tax_declaration].merge!({:collected_amount=>vat_collected_amount, :paid_amount=>vat_deductible_amount, :balance_amount=>vat_balance_amount, :assimilated_taxes_amount=>vat_assimilated_amount, :acquisition_amount=>vat_acquisitions_amount, :started_on=>started_on, :stopped_on=>stopped_on}))
  #     @tax_declaration.company_id = @current_company.id
  #     return if save_and_redirect(@tax_declaration)
      
  #   else
  #     @tax_declaration = TaxDeclaration.new

  #     if @tax_declaration.new_record?
  #       last_declaration = @current_company.tax_declarations.find(:last, :select=>"DISTINCT id, started_on, stopped_on, nature")
  #       if last_declaration.nil?
  #         @tax_declaration.nature = "normal"
  #         last_financialyear = @current_company.financialyears.find(:last, :conditions=>{:closed => true})
  #         @tax_declaration.started_on = last_financialyear.started_on
  #         @tax_declaration.stopped_on = last_financialyear.started_on.end_of_month
  #       else
  #         @tax_declaration.nature = last_declaration.nature
  #         @tax_declaration.started_on = last_declaration.stopped_on+1
  #         @tax_declaration.stopped_on = @tax_declaration.started_on+(last_declaration.stopped_on-last_declaration.started_on)-2          
  #       end
  #       @tax_declaration.stopped_on = params[:stopped_on].to_s if params.include? :stopped_on and params[:stopped_on].blank?
  #     end
      
  #   end       
    
  #   render_form
  # end


  # # this method updates a tax declaration.
  # def tax_declaration_update
  #   render_form
  # end


  # # this method computes the end of tax declaration depending the period choosen.
  # def tax_declaration_period_search
  #   if request.xhr?
  #     started_on =  params["started_on"].to_date
      
  #     @stopped_on=started_on.end_of_month if (["monthly"].include? params["period"])
  #     @stopped_on=(started_on.months_since 2).end_of_month.to_s if (["quarterly"].include? params["period"])
  #     @stopped_on=(started_on.months_since 11).end_of_month if (["yearly"].include? params["period"])
  #     @stopped_on='' if (["other"].include? params["period"])
      
  #     render :action=>"tax_declaration_period_search.rjs"

  #   end
  # end
  

  # # this method deletes a tax declaration.
  # def tax_declaration_delete
  #   if request.post? or request.delete?
  #     @tax_declaration = TaxDeclaration.find_by_id_and_company_id(params[:id], @current_company.id) 
  #     TaxDeclaration.destroy @tax_declaration
  #   end    
  #   redirect_to :action => "tax_declarations"
  # end


  def import
    
  end

end



