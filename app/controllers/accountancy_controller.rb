# == License
# Ekylibre - Simple ERP
# Copyright (C) 2009 Brice Texier, Thibaud Mérigon
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
  
  dyta(:accounts, :conditions=>{:company_id=>['@current_company.id']}, :order=>"number ASC") do |t|
    t.column :number
    t.column :name
    t.action :account_update
    t.action :account_delete, :method=>:post, :confirm=>:are_you_sure
  end
  
  dyta(:bank_accounts, :conditions=>{:company_id=>['@current_company.id']}, :order=>:name) do |t|
    t.column :name
    t.column :iban_label
    t.column :name, :through=>:journal
    t.column :name, :through=>:currency
    t.column :number, :through=>:account
    t.action :bank_account_update
    t.action :bank_account_delete, :method=>:post, :confirm=>:are_you_sure
  end
  
  dyta(:bank_account_statements, :conditions=>{:company_id=>['@current_company.id']}, :order=>"started_on ASC") do |t|
    t.column :number, :url=>{:action=>:bank_account_statement}
    t.column :started_on
    t.column :stopped_on
    t.action :bank_account_statement_update
    t.action :bank_account_statement_delete, :method=>:post, :confirm=>:are_you_sure
  end
  
  #
  def self.statements_entries_conditions(options={})
    code = ""
    code += "conditions = ['entries.company_id=? AND draft=?', @current_company.id, false] \n"

    code += "unless session[:statement].blank? \n"
    code += "statement = @current_company.bank_account_statements.find(:first, :conditions=>{:id=>session[:statement]})\n"
    code += "conditions[0] += ' AND statement_id = ? '\n"
    code += "conditions << statement.id \n"
    code += "end \n"
    code += "conditions \n"
    code
  end

  dyta(:statement_entries, :model =>:entries, :conditions=>statements_entries_conditions, :order=>:record_id) do |t|
    t.column :journal_name, :label=>'Journal'
    t.column :number, :label=>"Numéro", :through=>:record
    t.column :created_on, :label=>"Crée le", :through=>:record, :datatype=>:date
    t.column :printed_on, :label=>"Saisie le", :through=>:record, :datatype=>:date
    t.column :name
    t.column :number, :label=>"Compte", :through=>:account
    t.column :debit
    t.column :credit
  end
  
  dyta(:entries_draft, :model=>:entries, :conditions=>{:company_id=>['@current_company.id'], :draft=>true}, :order=>:record_id, :line_class=>'RECORD.mode') do |t|
    t.column :journal_name, :label=>'Journal'
    t.column :resource, :label=>'Type'
    t.column :resource_id, :label=>'Id', :through=>:record
    t.column :number, :label=>"Numéro", :through=>:record
    t.column :created_on, :label=>"Crée le", :through=>:record, :datatype=>:date
    t.column :printed_on, :label=>"Saisie le", :through=>:record, :datatype=>:date
    t.column :name
    t.column :number, :label=>"Compte" , :through=>:account
    t.column :debit
    t.column :credit
    t.action :entry_update, :if => '!RECORD.close?', :url=>{:action=>:entry_update, :accountize=>true}   
    t.action :entry_delete, :method => :post, :confirm=>:are_you_sure, :if => '!RECORD.close? and !RECORD.letter?'
  end
  
  #
  def self.entries_journal_consult_conditions(options={})
    code = ""
    code += "conditions=['entries.company_id=?', @current_company.id.to_s] \n"
    code += "unless session[:entries][:journal].blank? \n" 
    code += "journal=@current_company.journals.find(:first, :conditions=>{:id=>session[:entries][:journal]})\n" 
    code += "if journal\n"
    code += "conditions[0] += ' AND r.journal_id=? AND r.created_on > ?' \n"
    code += "conditions << journal.id \n"
    code += "conditions << journal.closed_on \n"
    code += "end \n"
    code+="end\n"
    
    code +="unless session[:entries][:financialyear].blank? \n"
    code += "financialyear = @current_company.financialyears.find(:first, :conditions=>{:id=>session[:entries][:financialyear]}) \n"
    code += "if financialyear \n"
    code += "conditions[0] += ' AND r.financialyear_id=?' \n"
    code += "conditions << financialyear.id \n"
    code += "end \n"
    code+="end\n"
    code += "conditions \n"
    
    code
    
  end
  
  dyta(:entries, :conditions=>entries_journal_consult_conditions, :order=>'record_id DESC', :joins=>"INNER JOIN journal_records r ON r.id = entries.record_id", :line_class=>'RECORD.balanced_record') do |t|
    t.column :journal_name, :label=>"Journal"
    t.column :number, :label=>"Numéro", :through=>:record
    t.column :created_on, :label=>"Crée le", :through=>:record, :datatype=>:date
    t.column :printed_on, :label=>"Saisie le", :through=>:record, :datatype=>:date
    t.column :name
    t.column :number, :label=>"Compte" , :through=>:account
    t.column :debit
    t.column :credit
    t.action :entry_update, :if => '!RECORD.close?'  
    t.action :entry_delete, :method => :post, :confirm=>:are_you_sure, :if => '!RECORD.close? and !RECORD.letter?'
  end
  
  dyta(:financialyears, :conditions=>{:company_id=>['@current_company.id']}, :order=>:started_on) do |t|
    t.column :code, :url=>{:action=>:financialyear}
    t.column :closed
    t.column :started_on,:url=>{:action=>:financialyear}
    t.column :stopped_on,:url=>{:action=>:financialyear}
    t.action :financialyear_close, :if => '!RECORD.closed and RECORD.closable?'
    t.action :financialyear_update, :if => '!RECORD.closed'  
    t.action :financialyear_delete, :method => :post, :confirm=>:are_you_sure, :if => '!RECORD.closed'  
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
  
  dyli(:account, [:number, :name], :conditions => {:company_id=>['@current_company.id']})
  dyli(:account_collected, [:number, :name], :model=>:account, :conditions => {:company_id=>['@current_company.id']})
  dyli(:account_paid, [:number, :name], :model=>:account, :conditions => {:company_id=>['@current_company.id']})
  
  # 
  def index
    @entries = @current_company.entries
  end
  
  #this method displays the form to choose the journal and financialyear.
  def accountize
    # unless @current_company.invoices or @current_company.sale_orders or @current_company.purchase_orders or @current_company.payments or @current_company.transfers
    #       flash[:message] = tc('messages.need_commercial_transactions_for_generate_entries')
    #       redirect_to :controller=>:management_controller, :action=>:index
    #       return
    #     end
  end
  
  #this method lists all the entries generated in draft mode.
  def draft_entries
    session[:limit_period] ||= params[:date_generation_entries].to_s
    session[:cashed_payments] ||= params[:cashed_payments].to_s
    
    if request.post? or request.xhr?
      #all the invoices are accountized.
      @invoices = @current_company.invoices.find(:all, :conditions=>["accounted_at IS NULL and amount != 0 AND CAST(created_on AS DATE) BETWEEN \'2007-01-01\' AND ?", session[:limit_period].to_s], :limit=>100)
      @invoices.each do |invoice|
        invoice.to_accountancy
      end
      
      # all the purchase_orders are accountized.
      @purchase_orders = @current_company.purchase_orders.find(:all, :conditions=>["accounted_at IS NULL AND created_on < ? ", session[:limit_period].to_s], :order=>"created_on DESC")                                                         
      @purchase_orders.each do |purchase_order|
        purchase_order.to_accountancy
      end
      
      #      # all the transfers are accountized.
      @transfers = @current_company.transfers.find(:all, :conditions=>["accounted_at IS NULL AND created_on < ? ", session[:limit_period].to_s],:order=>"created_on DESC")
      @transfers.each do |transfer|
        transfer.to_accountancy
      end
      
      # all the payments are comptabilized if they have been embanked or not.  
      #   join = "inner join embankments e on e.id=payments.embankment_id" unless session[:cashed_payments]
      #       @payments = @current_company.payments.find(:all, :conditions=>["payments.created_on < ? and payments.accounted_at IS NULL and payments.amount!=0", session[:limit_period].to_s], :joins=>join||nil, :order=>"created_on DESC", :limit=>100)    
      #       @payments.each do |payment|
      #         payment.to_accountancy
      #       end
      
      #       # the sale_orders are comptabilized if the matching payments and invoices have been already accountized.  
      #       @sale_orders = @current_company.sale_orders.find(:all, :conditions=>["sale_orders.created_on < ? and sale_orders.accounted_at IS NULL and p.accounted_at IS NOT NULL and i.accounted_at IS NOT NULL", session[:limit_period].to_s], :joins=>"inner join payment_parts part on part.expense_id=sale_orders.id and part.expense_type='#{SaleOrder.name}' inner join payments p on p.id=part.payment_id inner join invoices i on i.id=part.invoice_id",:order=>"created_on DESC", :limit=>100)    
      #       @sale_orders.each do |sale_order|
      #         sale_order.to_accountancy 
      #       end
      
    elsif request.put?
      Entry.update_all({:draft=> false}, {:company_id=>@current_company.id, :draft=> true}, :joins=>"inner join journal_records r on r.id=entries.record_id and r.created_on < #{session[:limit_period]}")
      redirect_to :action=>:accountize
    end
    
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
      redirect_to_back if @bank_account.save
    else
      @bank_account = BankAccount.new
      session[:entity_id] = params[:entity_id]||@current_company.entity_id
      @valid_account = @current_company.accounts.empty?
      @valid_journal = @current_company.journals.empty?  
    end
    render_form
  end

  # this method updates a bank_account with a form.
  def bank_account_update
    @bank_account = BankAccount.find_by_id_and_company_id(params[:id], @current_company.id)  
    if request.post? or request.put?
      if @bank_account.update_attributes(params[:bank_account])
        redirect_to :action => "bank_accounts"
      end
    end
    render_form
  end
  
  # this method deletes a bank_account.
  def bank_account_delete
    if request.post? or request.delete?
      @bank_account = BankAccount.find_by_id_and_company_id(params[:id], @current_company.id)  
      if @bank_account.statements.size > 0
        @bank_account.update_attribute(:deleted, true)
      else
        BankAccount.destroy @bank_account
      end
    end
    redirect_to :action => "bank_accounts"
  end

  # lists all the accounts with the credit, the debit and the balance for each of them.
  def accounts
  end
  
  # this action creates an account with a form.
  def account_create
    if request.post?
      @account = Account.new(params[:account])
      @account.company_id = @current_company.id
      redirect_to_back if @account.save
    else
      @account = Account.new
    end
    render_form
  end

  # this action updates an existing account with a form.
  def account_update
    @account = Account.find_by_id_and_company_id(params[:id], @current_company.id)  
    if request.post? or request.put?
      params[:account].delete :number
      redirect_to_back if @account.update_attributes(params[:account])
    end
    @title = {:value=>@account.label}
    render_form
  end

  # this action deletes or hides an existing account.
  def account_delete
    if request.post? or request.delete?
      @account = Account.find_by_id_and_company_id(params[:id], @current_company.id)  
      unless @account.entries.size > 0 or @account.balances.size > 0
        Account.destroy(@account.id) 
      end
    end
    redirect_to_current
  end
  
  PRINTS=[[:balance, {:partial=>"balance"}],
          [:general_ledger, {:partial=>"ledger"}],
          [:journal, {:partial=>"journal"}],
          [:journals, {:partial=>"journals"}],
          [:synthesis, {:partial=>"synthesis"}]]

  # this method prepares the print of document.
  def document_prepare
    @prints = PRINTS.select{|x| @current_company.document_templates.find_by_nature(x[0])}
    if request.post?
      session[:mode] = params[:print][:mode]
      redirect_to :action=>:document_print
    end
  end
  
  #  this method prints the document.
  def document_print
    for print in PRINTS
      @print = print if print[0].to_s == session[:mode]
    end
    @financialyears =  @current_company.financialyears.find(:all, :order => :stopped_on)
    if @financialyears.nil?
      flash[:message]=tc('messages.no_financialyear')
      redirect_to :action => :document_prepare
      return      
    end
    
    @partial = 'print_'+@print[1][:partial]
    started_on = Date.today.year.to_s+"-01-01"
    stopped_on = Date.today.year.to_s+"-12-31"
    
    if request.post? 
      lines = []
      if @current_company.default_contact
        lines =  @current_company.default_contact.address.split(",").collect{ |x| x.strip}
        lines << @current_company.default_contact.phone if !@current_company.default_contact.phone.nil?
        lines << @current_company.code
      end
      
      sum = {:debit=> 0, :credit=> 0, :balance=> 0}
      
      if session[:mode] == "journals"
        entries = @current_company.records(params[:printed][:from], params[:printed][:to])
        
        if entries.size > 0
          entries.each do |entry|
            sum[:debit] += entry.debit
            sum[:credit] += entry.credit
          end
          sum[:balance] = sum[:debit] - sum[:credit]
        end
        
        journal_template = @current_company.document_templates.find(:first, :conditions =>{:name => "Journal général"})
        if journal_template.nil?
          flash[:message]=tc('messages.no_template_journal')
          redirect_to :action=>:document_print
          return
        end
        
        pdf, filename = journal_template.print(@current_company, params[:printed][:from],  params[:printed][:to], entries, sum)
        send_data pdf, :type=>Mime::PDF, :filename=>filename
      end
      
      if session[:mode] == "journal"
        journal = Journal.find_by_id_and_company_id(params[:printed][:name], @current_company.id)
        id = @current_company.journals.find(:first, :conditions => {:name => journal.name }).id
        entries = @current_company.records(params[:printed][:from], params[:printed][:to], id)
        
        if entries.size > 0
          entries.each do |entry|
            sum[:debit] += entry.debit
            sum[:credit] += entry.credit
          end
          sum[:balance] = sum[:debit] - sum[:credit]
        end
        
        journal_template = @current_company.document_templates.find(:first, :conditions=>["name like ?", '%Journal auxiliaire%'])
        if journal_template.nil?
          flash[:message]=tc('messages.no_template_journal_by_id', :value=>journal.name)
          redirect_to :action=>:document_print
          return
        end

        pdf, filename = journal_template.print(journal, params[:printed][:from], params[:printed][:to], entries, sum)

        send_data pdf, :type=>Mime::PDF, :filename=>filename
      end
      
      if session[:mode] == "balance"
        accounts_balance = Account.balance(@current_company.id, params[:printed][:from], params[:printed][:to])
        accounts_balance.delete_if {|account| account[:credit].zero? and account[:debit].zero?}
        
        for account in accounts_balance
          sum[:debit] += account[:debit]
          sum[:credit] += account[:credit]
        end
        sum[:balance] = sum[:debit] - sum[:credit]
        
        balance_template = @current_company.document_templates.find(:first, :conditions =>{:name => "Balance"})
        if balance_template.nil?
          flash[:error]=tc("messages.no_balance_template")
          redirect_to :action=>:document_prepare
          return
        end
        
        pdf, filename = balance_template.print(@current_company, accounts_balance,  params[:printed][:from],  params[:printed][:to], sum)
        
        send_data pdf, :type=>Mime::PDF, :filename=>filename
        
      end

      if session[:mode] == "synthesis"
        @financialyear = Financialyear.find_by_id_and_company_id(params[:printed][:financialyear], @current_company.id)
        params[:printed][:name] = @financialyear.code
        params[:printed][:from] = @financialyear.started_on
        params[:printed][:to] = @financialyear.stopped_on
        @balance = Account.balance(@current_company.id, @financialyear.started_on, @financialyear.stopped_on)
        
        @balance.each do |account| 
          sum[:credit] += account[:credit] 
          sum[:debit] += account[:debit] 
        end
        sum[:balance] = sum[:debit] - sum[:credit]     
        
        @last_financialyear = @financialyear.previous(@current_company.id)
        
        if not @last_financialyear.nil?
          index = 0
          @previous_balance = Account.balance(@current_company.id, @last_financialyear.started_on, @last_financialyear.stopped_on)
          @previous_balance.each do |balance|
            @balance[index][:previous_debit]   = balance[:debit]
            @balance[index][:previous_credit]  = balance[:credit]
            @balance[index][:previous_balance] = balance[:balance]
            index+=1
          end
          session[:previous_financialyear] = true
        end
        
        #raise Exception.new lines.inspect
        
        session[:lines] = lines
        session[:printed] = params[:printed]
        session[:balance] = @balance
        
        redirect_to :action => :synthesis
      end
      
      if session[:mode] == "general_ledger"
        ledger = Account.ledger(@current_company.id, params[:printed][:from], params[:printed][:to])
        
        #raise Exception.new ledger.inspect
        
        ledger_template = @current_company.document_templates.find(:first, :conditions=>{:name=>"Grand livre"})

        
        
        pdf, filename = ledger_template.print(@current_company, ledger,  params[:printed][:from],  params[:printed][:to])
        
        send_data pdf, :type=>Mime::PDF, :filename=>filename
      end
      
    end

    @title = {:value=>::I18n.t("views.#{self.controller_name}.document_prepare.#{@print[0]}")}
  end
  
  # this method displays the income statement and the balance sheet.
  def synthesis
    @lines = session[:lines]
    @printed = session[:printed]
    @balance = session[:balance]
    @result = 0
    @solde = 0
    if session[:previous_financialyear] == true
      @previous_solde = 0
      @previous_result = 0
    end
    @active_fixed_sum = 0
    @active_current_sum = 0
    @passive_capital_sum = 0
    @passive_stock_sum = 0
    @passive_debt_sum = 0
    @previous_active_fixed_sum = 0
    @previous_active_current_sum = 0
    @previous_passive_capital_sum = 0
    @previous_passive_stock_sum = 0
    @previous_passive_debt_sum = 0
    @cost_sum = 0
    @finished_sum =  0
    @previous_active_sum = 0
    @previous_passive_sum = 0
    @previous_cost_sum = 0
    @previous_finished_sum = 0
    
    @balance.each do |account|
      @solde += account[:balance]
      @result = account[:balance] if account[:number].to_s.match /^12/
      @active_fixed_sum += account[:balance] if account[:number].to_s.match /^(20|21|22|23|26|27)/
      @active_current_sum += account[:balance] if account[:number].to_s.match /^(3|4|5)/ and account[:balance] >= 0
      @passive_capital_sum += account[:balance] if account[:number].to_s.match /^(1[^5])/
      @passive_stock_sum += account[:balance] if account[:number].to_s.match /^15/ 
      @passive_debt_sum += account[:balance] if account[:number].to_s.match /^4/ and account[:balance] < 0
      @cost_sum += account[:balance] if account[:number].to_s.match /^6/
      @finished_sum += account[:balance] if account[:number].to_s.match /^7/
      if session[:previous_financialyear] == true
        @previous_solde += account[:previous_balance] 
        @previous_result = account[:previous_balance] if account[:number].to_s.match /^12/
        @previous_active_fixed_sum += account[:previous_balance] if account[:number].to_s.match /^(20|21|22|23|26|27)/
        @previous_active_current_sum += account[:previous_balance] if account[:number].to_s.match /^(3|4|5)/ and account[:balance] >= 0
        @previous_passive_capital_sum += account[:previous_balance] if account[:number].to_s.match /^(1[^5])/
        @previous_passive_stock_sum += account[:previous_balance] if account[:number].to_s.match /^15/ 
        @previous_passive_debt_sum += account[:previous_balance] if account[:number].to_s.match /^4/ and account[:balance] < 0
        @previous_cost_sum += account[:previous_balance] if account[:number].to_s.match /^6/
        @previous_finished_sum += account[:previous_balance] if account[:number].to_s.match /^7/
      end
    end

    @title={:value=>"la période du "+@printed[:from].to_s+" au "+@printed[:to].to_s}
  end

  # this method orders sale.
  #def order_sale
  # render(:xil=>"#{RAILS_ROOT}/app/views/prints/sale_order.xml",:key=>params[:id])
  #end
  
  # lists all the bank_accounts with the mainly characteristics. 
  def financialyears
  end

  def financialyear
    return unless @financialyear = find_and_check(:financialyears, params[:id])
    @financialyear.compute_balances
    @title = {:code=>@financialyear.code}
  end
  
  # this action creates a financialyear with a form.
  def financialyear_create
    if request.post? 
      @financialyear = Financialyear.new(params[:financialyear])
      @financialyear.company_id = @current_company.id
      redirect_to_back if @financialyear.save
    else
      @financialyear = Financialyear.new
      f = @current_company.financialyears.find(:first, :order=>"stopped_on DESC")
      
      @financialyear.started_on = f.stopped_on+1.day unless f.nil?
      @financialyear.started_on ||= Date.today
      @financialyear.stopped_on = (@financialyear.started_on+1.year-1.day).end_of_month
      @financialyear.code = @financialyear.started_on.year.to_s
      @financialyear.code += '/'+@financialyear.stopped_on.year.to_s if @financialyear.started_on.year!=@financialyear.stopped_on.year
    end
    
    render_form
  end
  
  
  # this action updates a financialyear with a form.
  def financialyear_update
    @financialyear = Financialyear.find_by_id_and_company_id(params[:id], @current_company.id)  
    if request.post? or request.put?
      redirect_to :action => "financialyears"  if @financialyear.update_attributes(params[:financialyear])
    end
    render_form
  end
  
  # this action deletes a financialyear.
  def financialyear_delete
    if request.post? or request.delete?
      @financialyear = Financialyear.find_by_id_and_company_id(params[:id], @current_company.id)  
      Financialyear.destroy @financialyear unless @financialyear.records.size > 0 
    end
    redirect_to :action => "financialyears"
  end
  
  
  # This method allows to close the financialyear.
  def financialyear_close
    @financialyears = []

    financialyears = Financialyear.find(:all, :conditions => {:company_id => @current_company.id, :closed => false})
    
    financialyears.each do |financialyear|
      @financialyears << financialyear if financialyear.closable?
    end
    
    if @financialyears.empty? 
      flash[:message]=tc(:no_closable_financialyear)
      redirect_to :action => :financialyears
      return
    end
    
    if params[:id]  
      @financialyear = Financialyear.find_by_id_and_company_id(params[:id], @current_company.id) 
    else
      @financialyear = @financialyears.first
    end

    @renew_journal = @current_company.journals.find(:all, :conditions => {:nature => :renew.to_s, :deleted => false})
    
    if request.post?
      @financialyear= Financialyear.find_by_id_and_company_id(params[:financialyear][:id], @current_company.id)  
      
      unless params[:journal_id].blank?
        @renew_journal = Journal.find(params[:journal_id])
        @new_financialyear = @financialyear.next(@current_company.id)
        
        if @new_financialyear.nil?
          flash[:message]=tc(:next_illegal_period_financialyear)
          redirect_to :action => :financialyears
          return
        end
        
        balance_account = generate_balance_account(@current_company.id, @financialyear.started_on, @financialyear.stopped_on)
        
        if balance_account.size > 0
          @record = JournalRecord.create!(:financialyear_id => @new_financialyear.id, :company_id => @current_company.id, :journal_id => @renew_journal.id, :created_on => @new_financialyear.started_on, :printed_on => @new_financialyear.started_on)
          result=0
          account_profit_id=0
          account_loss_id=0
          account_profit_name=''
          account_loss_name=''
          balance_account.each do |account|
            if account[:number].to_s.match /^120/
              account_profit_id = account[:id]
              account_profit_name = account[:name]
              result += account[:balance]
            elsif account[:number].to_s.match /^129/
              account_loss_id = account[:id]
              account_loss_name = account[:name]
              result -= account[:balance]
            elsif account[:number].to_s.match /^(6|7)/
              result += account[:balance] 
            else
              @entry=@current_company.entries.create({:record_id => @record.id, :currency_id => @renew_journal.currency_id, :account_id => account[:id], :name => account[:name], :currency_debit => account[:debit], :currency_credit => account[:credit]})
            end
          end
          if result.to_i > 0
            @entry=@current_company.entries.create({:record_id => @record.id, :currency_id => @renew_journal.currency_id, :account_id => account_loss_id, :name => account_loss_name, :currency_debit => result, :currency_credit => 0.0}) 
          else
            @entry=@current_company.entries.create({:record_id => @record.id, :currency_id => @renew_journal.currency_id, :account_id => account_profit_id, :name => account_profit_name, :currency_debit => 0.0, :currency_credit => result.abs}) 
          end
        end
      end
      @financialyear.close(params[:financialyear][:stopped_on])
      flash[:message] = tc('messages.closed_financialyears')
      redirect_to :action => :financialyears
      
    else
      if @financialyear
        @financialyear_records = []
        d = @financialyear.started_on
        while d.end_of_month < @financialyear.stopped_on
          d=(d+1).end_of_month
          @financialyear_records << d.to_s(:attributes)
        end
      end
    end
    
  end
  
  
  # this method generates a table with debit and credit for each account.
  def generate_balance_account(company, from, to)
    balance = []
    debit = 0
    credit = 0
    return Account.balance(company, from, to)
  end
  
  #
  def financialyears_records
    @financialyear_records=[]
    @financialyear = Financialyear.find(params[:financialyear_select])
    d = @financialyear.started_on
    
    while d.end_of_month < @financialyear.stopped_on
      d=(d+1).end_of_month
      @financialyear_records << d.to_s(:attributes)
    end
    render :text => options_for_select(@financialyear_records)
  end
  
  def auto_complete_for_entry_account
    #puts params.inspect
    pattern = '%'+params[:entry][:account].to_s.lower.strip.gsub(/\s+/,'%').gsub(/[#{String::MINUSCULES.join}]/,'_')+'%'
    @accounts = @current_company.accounts.find(:all, :conditions => [ 'LOWER(number) LIKE ? ', pattern], :order => "name ASC", :limit=>10)
    render :inline => "<%=content_tag(:ul, @accounts.map { |account| content_tag(:li, h(account.label)) })%>"
  end

  #this method allows to enter the accountancy records within a form.
  def entries
    session[:entries] ||= {}
    
    @journals = @current_company.journals.find(:all, :order=>:name)
    @financialyears = @current_company.financialyears.find(:all, :conditions => {:closed => false}, :order=>:code)
    
    unless @financialyears.size>0
      flash[:message] = tc('messages.need_financialyear_to_consult_record_entries')
      redirect_to :action=>:financialyear_create
      return
    end
    unless @journals.size>0
      flash[:message] = tc('messages.need_journal_to_consult_record_entries')
      redirect_to :action=>:journal_create
      return
    end

    if params[:journal_id] and params[:financialyear_id]
      if not params[:journal_id].match /---/
        session[:entries][:journal] = params[:journal_id] 
      else
        session[:entries][:journal] = ' '
      end
      if not params[:financialyear_id].match /---/
        session[:entries][:financialyear] = params[:financialyear_id]
      else
        session[:entries][:financialyear] = ' '
      end
    end

    session[:entries][:error_balance_or_new_record] = false

    @records=[]
    @journal = find_and_check(:journal, session[:entries][:journal]) unless session[:entries][:journal].blank?
    @financialyear = find_and_check(:financialyear, session[:entries][:financialyear]) unless session[:entries][:financialyear].blank?
    @valid = (!@journal.nil? and !@financialyear.nil?)
    # @financialyear.compute_balances
    # @financialyear.balance("51D,53,54,^5181,^519")
    # @financialyear.balance("707 ")
    # template = @current_company.document_templates.find(:first, :conditions=>["name like ?", '%Bilan%'])
    # pdf, filename = template.print(@financialyear)

    #    send_data pdf, :type=>Mime::PDF, :filename=>filename
    #raise Exception.new @financialyear.inspect
    
    if @valid
      @record = JournalRecord.new
      @entry = Entry.new 
      
      @records = @journal.records.find(:all, :conditions => {:financialyear_id => @financialyear.id, :company_id => @current_company.id }, :order=>"number DESC") 
      
      unless session[:entries][:error_balance_or_new_record]
        @record = @journal.records.find(:first, :conditions => ["debit!=credit OR (debit=0 AND credit=0) AND financialyear_id = ?", @financialyear.id], :order=>:id) if @record.balanced or @record.new_record?
      end
      
      unless @record.nil?
        if (@record.balance > 0) 
          @entry.currency_credit=@record.balance.abs 
        else
          @entry.currency_debit=@record.balance.abs  
        end
      end
      
      unless session[:entries][:error_balance_or_new_record]
        @record = JournalRecord.new(params[:record]) if @record.nil? 
        
        if @record.new_record?
          @record.number = @records.size>0 ? @records.first.number.succ : 1
          @record.created_on = @records.size>0 ? @records.last.created_on : @financialyear.started_on
          @record.printed_on = @records.size>0 ? @records.last.printed_on : @financialyear.started_on
        end
      end
      
    end  
  end

  #this method allows to create an entry.
  def entry_create
    if request.xhr? 
      @record = @current_company.journal_records.find(:first,:conditions=>["journal_id = ? AND number = ? AND financialyear_id = ?", session[:entries][:journal].to_s, params[:record][:number].rjust(6,"0"), session[:entries][:financialyear].to_s])       
      created_on = params[:record][:created_on].gsub('/','-').to_date.strftime
      printed_on = params[:record][:printed_on].gsub('/', '-').to_date.strftime

      if @record
        if @record.created_on > @record.journal.closed_on
          @record.created_on = created_on
          @record.printed_on = printed_on
        end
      end
      
      if @record.nil?
        @record = JournalRecord.create!(params[:record].merge({:financialyear_id => session[:entries][:financialyear].to_s, :journal_id => session[:entries][:journal].to_s, :company_id => @current_company.id, :created_on => created_on, :printed_on => printed_on}))
      end 
      
      params[:entry][:account] = @current_company.accounts.find(:first, :conditions=>["LOWER(number) LIKE ? ",params[:entry][:account].strip.split(/[^0-9A-Z]/)[0].lower ])
      
      #raise Exception.new account.inspect
      @entry = @current_company.entries.build(params[:entry])
      
      if @record.save
        @entry.record_id = @record.id
        @entry.currency_id = find_and_check(:journal, session[:entries][:journal]).currency_id
        if @entry.save
          @record.reload
          @record = @record.next if @record.balanced
          @entry = @entry.next(@record.balance)
        end
        
      else
        session[:entries][:error_balance_or_new_record] = true if @record.balanced or @record.new_record?
        @entry = Entry.new
      end
      
      render :action=>"entry_create.rjs" 
    end
  end

  # this method updates an entry within a form.
  def entry_update
    session[:accountize] ||= params[:accountize] if params[:accountize]
    @entry = Entry.find_by_id_and_company_id(params[:id], @current_company.id)  
    if request.post? or request.put?
      @entry.update_attributes(params[:entry]) 
      unless session[:accountize].nil?
        session[:accountize]=nil
        redirect_to :action=>:draft_entries, :method=>:post
      else
        redirect_to_back
      end
    end
    render_form
  end

  # this method deletes an entry with a form.
  def entry_delete
    if request.post? or request.delete?
      @entry = Entry.find_by_id_and_company_id(params[:id], @current_company.id) 
      Entry.destroy(@entry.id)
      redirect_to :action => "entries"
    end
  end


  dyta(:journals, :conditions=>{:company_id=>['@current_company.id']}, :order=>:code) do |t|
    t.column :name
    t.column :code
    t.column :nature_label
    t.column :name, :through=>:currency
    t.column :closed_on
    t.action :print, :url=>{:controller=>:company, :type=>:journal}
    t.action :journal_close, :if => 'RECORD.closable?(Date.today)'
    t.action :journal_update
    t.action :journal_delete, :method=>:post, :confirm=>:are_you_sure
  end
  

  # lists all the transactions established on the accounts, sorted by date.
  def journals
  end


  #this method creates a journal with a form. 
  def journal_create
    if request.post?
      @journal = Journal.new(params[:journal])
      @journal.company_id = @current_company.id
      redirect_to_back if @journal.save
    else
      @journal = Journal.new
      @journal.nature = Journal.natures[0][1]
    end
    render_form
  end

  #this method updates a journal with a form. 
  def journal_update
    @journal = Journal.find_by_id_and_company_id(params[:id], @current_company.id)  
    
    if request.post? or request.put?
      @journal.update_attributes(params[:journal]) 
      redirect_to :action => "journals" 
    end
    render_form
  end

  # this action deletes or hides an existing journal.
  def journal_delete
    if request.post? or request.delete?
      @journal = Journal.find_by_id_and_company_id(params[:id], @current_company.id)  
      if @journal.records.size > 0
        flash[:message]=tc(:messages, :need_empty_journal_to_delete)
        @journal.update_attribute(:deleted, true)
      else
        Journal.destroy(@journal)
      end
    end
    redirect_to :action => "journals"
  end


  # This method allows to close the journal.
  def journal_close
    @journal_records = []
    @journals = []
    
    journals= @current_company.journals.find(:all, :conditions=> ["closed_on < ?", Date.today.to_s]) 
    journals.each do |journal|
      @journals << journal if journal.balance?
    end
    
    if @journals.empty?
      flash[:message]=tc(:no_closable_journal)
      redirect_to :action => :journals
    end
    
    if params[:id]  
      @journal = Journal.find_by_id_and_company_id(params[:id], @current_company.id) 
      # unless @journal.closable?(Date.today)
      #         flash[:message]=tc(:unclosable_journal)
      #         redirect_to :action => :journals 
      #       end
    else
      @journal = @current_company.journals.find(:first, :conditions=> ["closed_on < ?", Date.today.to_s]) 
    end
    
    if @journal
      d = @journal.closed_on
      while d.end_of_month < Date.today
        d=(d+1).end_of_month
        @journal_records << d.to_s(:attributes)
      end
    end
    
    if request.post?
      @journal = Journal.find_by_id_and_company_id(params[:journal][:id], @current_company.id)
      
      if @journal.nil?
        flash[:error] = tc(:unavailable_journal)
      end  
      
      if @journal.close(params[:journal][:closed_on])
        redirect_to_back
      end
    end
  end

  # This method allows to build the table of the periods.
  def journals_records
    @journals_records=[]
    @journal = Journal.find(params[:journal_select])
    d = @journal.closed_on
    while d.end_of_month < Date.today
      d=(d+1).end_of_month
      @journals_records << d.to_s(:attributes)
    end
    render :text => options_for_select(@journals_records) 
  end
  

  # This method allows to make lettering for the client and supplier accounts.
  def lettering
    clients_account = @current_company.parameter('accountancy.third_accounts.clients').value.to_s
    suppliers_account = @current_company.parameter('accountancy.third_accounts.suppliers').value.to_s
    
    Account.create!(:name=>"Clients", :number=>clients_account, :company_id=>@current_company.id) unless @current_company.accounts.exists?(:number=>clients_account)
    Account.create!(:name=>"Fournisseurs", :number=>suppliers_account, :company_id=>@current_company.id) unless @current_company.accounts.exists?(:number=>suppliers_account)

    @accounts_supplier = @current_company.accounts.find(:all, :conditions => ["number LIKE ?", suppliers_account+'%'])
    @accounts_client = @current_company.accounts.find(:all, :conditions => ["number LIKE ?", clients_account+'%'])
    
    @financialyears = @current_company.financialyears.find(:all)
    
    @entries =  @current_company.entries.find(:all, :conditions => ["editable = ? AND draft=? AND (a.number LIKE ? OR a.number LIKE ?)", false, false,clients_account+'%', suppliers_account+'%'], :joins => "LEFT JOIN accounts a ON a.id = entries.account_id")

    unless @entries.size > 0
      flash[:message] = tc('messages.need_entries_to_letter')
      return
    end

    if request.post?
      @account = @current_company.accounts.find(params[:account_client_id], params[:account_supplier_id])
      redirect_to :action => "account_letter", :id => @account.id
    end

  end

  # this method displays the array for make lettering.
  def account_letter
    @entries = @current_company.entries.find(:all, :conditions => { :account_id => params[:id]}, :joins => "INNER JOIN journal_records r ON r.id = entries.record_id INNER JOIN financialyears f ON f.id = r.financialyear_id", :order => "id ASC")

    session[:letter]='AAAA'
    
    @account = @current_company.accounts.find(params[:id])
    
    @title = {:value1 => @account.number}
  end


  # this method makes the lettering.
  def entry_letter

    if request.xhr?
      
      @entry = @current_company.entries.find(params[:id])
      
      @entries = @current_company.entries.find(:all, :conditions => { :account_id => @entry.account_id}, :joins => "INNER JOIN journal_records r ON r.id = entries.record_id INNER JOIN financialyears f ON f.id = r.financialyear_id", :order => "id ASC")
      
      @letters = []
      @entries.each do |entry|
        @letters << entry.letter unless entry.letter.blank?  
      end
      @letters.uniq!
      
      if @entry.letter != ""
        @entries_letter = @current_company.entries.find(:all, :conditions => ["letter = ? AND account_id = ?", @entry.letter.to_s, @entry.account_id], :joins => "INNER JOIN journal_records r ON r.id = entries.record_id INNER JOIN financialyears f ON f.id = r.financialyear_id")

        @entry.update_attribute("letter", '')
        
      else
        
        if not @letters.empty? 
          
          @letters.each do |letter|
            
            @entries_letter = @current_company.entries.find(:all, :conditions => ["letter = ? AND account_id = ?", letter.to_s, @entry.account_id], :joins => "INNER JOIN journal_records r ON r.id = entries.record_id INNER JOIN financialyears f ON f.id = r.financialyear_id")
            
            if @entries_letter.size > 0
              sum_debit = 0
              sum_credit = 0
              @entries_letter.each do |entry|
                sum_debit += entry.debit
                sum_credit += entry.credit
              end
              
              if sum_debit != sum_credit
                session[:letter] = letter
                break
              else
                session[:letter] = letter.succ
              end
            end
          end
        end
        @entry.update_attribute("letter", session[:letter].to_s)
      end
      
      @entries = @current_company.entries.find(:all, :conditions => { :account_id => @entry.account_id}, :joins => "INNER JOIN journal_records r ON r.id = entries.record_id INNER JOIN financialyears f ON f.id = r.financialyear_id", :order => "id ASC")
      
      render :action => "account_letter.rjs"
    end

  end
  
  # lists all the statements in details for a precise account.
  def statements  
    @bank_accounts = @current_company.bank_accounts
    @valid = @current_company.bank_accounts.empty?
    unless @bank_accounts.size>0
      flash[:message] = tc('messages.need_bank_account_to_record_statements')
      redirect_to :action=>:bank_account_create
      return
    end
  end

  # This method creates a statement.
  def bank_account_statement_create
    @bank_accounts = @current_company.bank_accounts  
    
    if request.post?
      @statement = BankAccountStatement.new(params[:statement])
      @statement.bank_account_id = params[:statement][:bank_account_id]
      @statement.company_id = @current_company.id
      
      if BankAccount.find_by_id_and_company_id(params[:statement][:bank_account_id], @current_company.id).account.entries.find(:all, :conditions => "statement_id is NULL").size.zero?
        flash[:message]=tc('messages.no_entries_pointable_for_bank_account')
      else
        
        if @statement.save
          redirect_to :action => "bank_account_statement_point", :id => @statement.id 
        end
      end
    else
      @statement = BankAccountStatement.new(:started_on=>Date.today-1.month-2.days, :stopped_on=>Date.today-2.days)
    end
    render_form 
  end


  # This method updates a statement.
  def bank_account_statement_update
    @bank_accounts = BankAccount.find(:all,:conditions=>"company_id = "+@current_company.id.to_s)  
    @statement = BankAccountStatement.find_by_id_and_company_id(params[:id], @current_company.id)  
    if request.post? or request.put?
      @statement.update_attributes(params[:statement]) 
      redirect_to :action => "statements_point", :id => @statement.id if @statement.save 
    end
    render_form
  end


  # This method deletes a statement.
  def bank_account_statement_delete
    if request.post? or request.delete?
      @statement = BankAccountStatement.find_by_id_and_company_id(params[:id], @current_company.id)  
      BankAccountStatement.destroy @statement
      redirect_to :action=>"statements"
    end
  end


  # This method displays the list of entries recording to the bank account for the given statement.
  def bank_account_statement_point
    session[:statement] = params[:id]  if request.get? 
    @bank_account_statement=BankAccountStatement.find(session[:statement])
    @bank_account=BankAccount.find(@bank_account_statement.bank_account_id)
    
    @entries=@current_company.entries.find(:all, :conditions =>["account_id = ? AND editable = ? AND draft=? AND CAST(j.created_on AS DATE) BETWEEN ? AND ?", @bank_account.account_id, true, false,  @bank_account_statement.started_on, @bank_account_statement.stopped_on], :joins => "INNER JOIN journal_records j ON j.id = entries.record_id", :order => "statement_id DESC")
    
    unless @entries.size > 0
      flash[:message] = tc('messages.need_entries_to_point', :value=>@bank_account_statement.number)
      redirect_to :action=>'statements'
    end

    if request.xhr?
      
      @entry=Entry.find(params[:id]) 

      if @entry.statement_id.eql? session[:statement].to_i
        
        @entry.update_attribute("statement_id", nil)
        @bank_account_statement.credit -= @entry.debit
        @bank_account_statement.debit  -= @entry.credit
        @bank_account_statement.save
        
      elsif @entry.statement_id.nil?
        @entry.update_attribute("statement_id", session[:statement])
        @bank_account_statement.credit += @entry.debit
        @bank_account_statement.debit  += @entry.credit
        @bank_account_statement.save
        
      else
        @entry.statement.debit  -= @entry.credit
        @entry.statement.credit -= @entry.debit
        @entry.statement.save
        @entry.update_attribute("statement_id", nil)
      end
      
      render :action => "statements.rjs" 
      
    end
    @title = {:value1 => @bank_account_statement.number, :value2 => @bank_account.name }
  end

  # displays in details the statement choosen with its mainly characteristics.
  def bank_account_statement
    @bank_account_statement = BankAccountStatement.find(params[:id])
    session[:statement]=params[:id]
    @title = {:value => @bank_account_statement.number}
  end
  
  #
  dyta(:tax_declarations, :conditions=>{:company_id=>['@current_company.id']}, :order=>:declared_on) do |t|
    t.column :nature, :label=>"Régime"
    t.column :address
    t.column :declared_on, :datatype=>:date
    t.column :paid_on, :datatype=>:date
    t.column :amount
    t.action :tax_declaration, :image => :show
    t.action :tax_declaration_update, :image => :update #:if => '!RECORD.submitted?'  
    t.action :tax_declaration_delete, :image => :delete,  :method => :post, :confirm=>:are_you_sure #, :if => '!RECORD.submitted?'
    
  end
  
  #   
  def taxes
    
  end
  
  manage :taxes, :nature=>":percent"

  # this method lists all the tax declarations.
  def tax_declarations
    @journals  =  @current_company.journals.find(:all, :conditions => ["nature = ? OR nature = ?", :sale.to_s,  :purchase.to_s])
    
    if @journals.nil?
      flash[:message] = tc('messages.need_journal_to_record_tax_declaration')
      redirect_to :action=>:journal_create
      return
    else
      @journals.each do |journal|
        unless journal.closable?(Date.today)
          flash[:message] = tc('messages.need_balanced_journal_to_tax_declaration')
          redirect_to :action=>:entries
          return
        end
      end

    end

  end

  # this method creates a tax declaration.
  def tax_declaration_create
    
    @financialyears = @current_company.financialyears.find(:all, :conditions => ["closed = 't'"])
    
    unless @financialyears.size > 0
      flash[:message] = tc('messages.need_closed_financialyear_to_declaration')
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
      redirect_to_back if  @tax_declaration.save
      
    else
      @tax_declaration = TaxDeclaration.new

      if @tax_declaration.new_record?
        last_declaration = @current_company.tax_declarations.find(:last, :select=>"DISTINCT id, started_on, stopped_on, nature")
        if last_declaration.nil?
          @tax_declaration.nature = "normal"
          last_financialyear = @current_company.financialyears.find(:last, :conditions=>{:closed => true})
          @tax_declaration.started_on = last_financialyear.started_on
          @tax_declaration.stopped_on = last_financialyear.started_on.end_of_month
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
  

  # this method updates a tax declaration.
  def tax_declaration_update
    render_form
  end

  # this method deletes a tax declaration.
  def tax_declaration_delete
    if request.post? or request.delete?
      @tax_declaration = TaxDeclaration.find_by_id_and_company_id(params[:id], @current_company.id) 
      TaxDeclaration.destroy @tax_declaration
    end    
    redirect_to :action => "tax_declarations"
  end


  # this method displays the tax declaration in details.
  def tax_declaration
    @tax_declaration = @current_company.tax_declarations.find(params[:id])
    
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
      # @sale_fixed_amount = @current_company.filtering_entries(:credit, ['775*'], [@tax_declaration.period_begin, @period_end])
      # @vat_sale_fixed_amount = @current_company.filtering_entries(:debit, ['44551*'], [@tax_declaration.period_begin, @period_end])

      # @oneself_deliveries_amount = @current_company.filtering_entries(:credit, ['772000*'], [@tax_declaration.period_begin, @period_end])
    end

    # payback of vat credits.
    @vat_payback_amount = @current_company.filtering_entries(:debit, ['44583*'], [@tax_declaration.started_on, @tax_declaration.stopped_on])

    @title = {:nature => tc(@tax_declaration.nature), :started_on => @tax_declaration.started_on, :stopped_on => @tax_declaration.stopped_on }
  end
  
end



