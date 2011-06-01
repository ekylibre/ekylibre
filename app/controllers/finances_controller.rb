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

class FinancesController < ApplicationController

  dyli(:account, ["number:X%", :name], :conditions =>{:company_id=>['@current_company.id']})
  dyli(:collected_account, ["number:X%", :name], :model=>:account, :conditions => {:company_id=>['@current_company.id']})
  dyli(:entities, [:code, :full_name], :conditions => {:company_id=>['@current_company.id']})
  dyli(:paid_account, ["number:X%", :name], :model=>:account, :conditions => {:company_id=>['@current_company.id']})


  def index
  end


  create_kame(:cashes, :conditions=>{:company_id=>['@current_company.id']}, :order=>:name) do |t|
    t.column :name, :url=>{:action=>:cash}
    t.column :nature_label
    t.column :name, :through=>:currency
    t.column :number, :through=>:account, :url=>{:action=>:account, :controller=>:accountancy}
    t.column :name, :through=>:journal, :url=>{:action=>:journal, :controller=>:accountancy}
    t.action :cash_update
    t.action :cash_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  # lists all the cashes with the mainly characteristics. 
  def cashes
  end

  create_kame(:cash_deposits, :model=>:deposits, :conditions=>{:company_id=>['@current_company.id'], :cash_id=>['session[:current_cash_id]']}, :order=>"created_on DESC") do |t|
    t.column :number, :url=>{:action=>:deposit}
    t.column :created_on
    t.column :payments_count
    t.column :amount
    t.column :name, :through=>:mode
    t.column :comment
  end

  create_kame(:cash_bank_statements, :model=>:bank_statements, :conditions=>{:company_id=>['@current_company.id'], :cash_id=>['session[:current_cash_id]']}, :order=>"started_on DESC") do |t|
    t.column :number, :url=>{:action=>:bank_statement, :controller=>:accountancy}
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

  create_kame(:cash_transfers, :conditions=>["#{CashTransfer.table_name}.company_id = ? ", ['@current_company.id']]) do |t|
    t.column :number, :url=>{:action=>:cash_transfer}
    t.column :emitter_amount
    t.column :name, :through=>:emitter_currency
    t.column :name, :through=>:emitter_cash, :url=>{:action=>:cash}
    t.column :receiver_amount
    t.column :name, :through=>:receiver_currency
    t.column :name, :through=>:receiver_cash, :url=>{:action=>:cash}
    t.column :created_on
    t.column :comment
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




  












  create_kame(:deposits, :conditions=>{:company_id=>['@current_company.id']}, :order=>"created_at DESC") do |t|
    t.column :number, :url=>{:action=>:deposit}
    t.column :amount, :url=>{:action=>:deposit}
    t.column :payments_count
    t.column :name, :through=>:cash, :url=>{:action=>:cash}
    t.column :label, :through=>:responsible
    t.column :created_on
    t.action :print, :url=>{:controller=>:company, :p0=>"RECORD.id", :id=>:deposit}
    t.action :deposit_update, :if=>'RECORD.locked == false'
    t.action :deposit_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>'RECORD.locked == false'
  end

  create_kame(:deposit_payments, :model=>:incoming_payments, :conditions=>{:company_id=>['@current_company.id'], :deposit_id=>['session[:deposit_id]']}, :per_page=>1000, :order=>:number) do |t|
    t.column :number, :url=>{:action=>:incoming_payment}
    t.column :full_name, :through=>:payer, :url=>{:controller=>:relations, :action=>:entity}
    t.column :bank
    t.column :account_number
    t.column :check_number
    t.column :paid_on
    t.column :amount, :url=>{:action=>:incoming_payment}
  end

  create_kame(:depositable_payments, :model=>:incoming_payments, :conditions=>["#{IncomingPayment.table_name}.company_id=? AND (deposit_id=? OR (mode_id=? AND deposit_id IS NULL))", ['@current_company.id'], ['session[:deposit_id]'], ['session[:payment_mode_id]']], :pagination=>:none, :order=>"to_bank_on, created_at", :line_class=>"((RECORD.to_bank_on||Date.yesterday)>Date.today ? 'critic' : '')") do |t|
    t.column :number, :url=>{:action=>:incoming_payment}
    t.column :full_name, :through=>:payer, :url=>{:action=>:entity, :controller=>:relations}
    t.column :bank
    t.column :account_number
    t.column :check_number
    t.column :paid_on
    t.column :label, :through=>:responsible
    t.column :amount
    t.check_box :to_deposit, :value=>'(RECORD.to_bank_on<=Date.today and (session[:deposit_id].nil? ? (RECORD.responsible.nil? or RECORD.responsible_id==@current_user.id) : (RECORD.deposit_id==session[:deposit_id])))', :label=>tc(:to_deposit)
  end


  def deposits
    notify(:no_depositable_payments, :now) if @current_company.depositable_payments.size <= 0
  end

  def deposit
    return unless @deposit = find_and_check(:deposit)
    session[:deposit_id] = @deposit.id
    t3e @deposit.attributes
  end
 
  def deposit_create
    mode = @current_company.incoming_payment_modes.find_by_id(params[:mode_id])
    if mode.nil?
      notify(:need_payment_mode_to_create_deposit, :warning)
      redirect_to :action=>:deposits
      return
    end
    if mode.depositable_payments.size <= 0
      notify(:no_payment_to_deposit, :warning)
      redirect_to :action=>:deposits
      return
    end
    session[:deposit_id] = nil
    session[:payment_mode_id] = mode.id
    if request.post?
      @deposit = Deposit.new(params[:deposit])
      # @deposit.mode_id = @current_company.payment_modes.find(:first, :conditions=>{:mode=>"check"}).id if @current_company.payment_modes.find_all_by_mode("check").size == 1
      @deposit.mode_id = mode.id 
      @deposit.company_id = @current_company.id 
      if saved = @deposit.save
        payments = params[:depositable_payments].collect{|id, attrs| (attrs[:to_deposit].to_i==1 ? id.to_i : nil)}.compact
        IncomingPayment.update_all({:deposit_id=>@deposit.id}, ["company_id=? AND id IN (?)", @current_company.id, payments])
        @deposit.refresh
      end
      return if save_and_redirect(@deposit, :saved=>saved)
    else
      @deposit = Deposit.new(:created_on=>Date.today, :mode_id=>mode.id, :responsible_id=>@current_user.id)
    end
    t3e :mode=>mode.name
    render_form
  end


  def deposit_update
    return unless @deposit = find_and_check(:deposit)
    session[:deposit_id] = @deposit.id
    session[:payment_mode_id] = @deposit.mode_id
    if request.post?
      if @deposit.update_attributes(params[:deposit])
        ActiveRecord::Base.transaction do
          payments = params[:depositable_payments].collect{|id, attrs| (attrs[:to_deposit].to_i==1 ? id.to_i : nil)}.compact
          IncomingPayment.update_all({:deposit_id=>nil}, ["company_id=? AND deposit_id=?", @current_company.id, @deposit.id])
          IncomingPayment.update_all({:deposit_id=>@deposit.id}, ["company_id=? AND id IN (?)", @current_company.id, payments])
        end
        @deposit.refresh
        redirect_to :action=>:deposit, :id=>@deposit.id
      end
    end
    t3e @deposit.attributes
    render_form
  end
  

  def deposit_delete
    return unless @deposit = find_and_check(:deposit)
    if request.post? or request.delete?
      @deposit.destroy
    end
    redirect_to_current
  end
  

  create_kame(:unvalidated_deposits, :model=>:deposits, :conditions=>{:locked=>false, :company_id=>['@current_company.id']}) do |t|
    t.column :created_on
    t.column :amount
    t.column :payments_count
    t.column :name, :through=>:cash
    t.check_box :validated, :value=>'RECORD.created_on<=Date.today-(15)'
  end

  def unvalidated_deposits
    @deposits = @current_company.deposits_to_lock
    if request.post?
      for id, values in params[:unvalidated_deposits]
        return unless deposit = find_and_check(:deposit, id)
        deposit.update_attributes!(:locked=>true) if deposit and values[:validated].to_i == 1
      end
      redirect_to :action=>:unvalidated_deposits
    end
  end
  





  def self.incoming_payments_conditions(options={})
    code = search_conditions(:incoming_payments, :incoming_payments=>[:amount, :used_amount, :check_number, :number], :entities=>[:code, :full_name])+"||=[]\n"
    code += "if session[:incoming_payment_state] == 'unreceived'\n"
    code += "  c[0] += ' AND received=?'\n"
    code += "  c << false\n"
    code += "elsif session[:incoming_payment_state] == 'waiting'\n"
    code += "  c[0] += ' AND to_bank_on > ?'\n"
    code += "  c << Date.today\n"
    code += "elsif session[:incoming_payment_state] == 'undeposited'\n"
    code += "  c[0] += ' AND deposit_id IS NULL'\n"
    code += "elsif session[:incoming_payment_state] == 'unparted'\n"
    code += "  c[0] += ' AND used_amount != amount'\n"
    code += "end\n"
    code += "c\n"
    return code
  end
 
  # create_kame(:incoming_payments, :conditions=>incoming_payments_conditions, :joins=>"LEFT JOIN #{Entity.table_name} AS entities ON entities.id = #{IncomingPayment.table_name}.payer_id", :order=>"to_bank_on DESC") do |t|
  create_kame(:incoming_payments, :conditions=>incoming_payments_conditions, :joins=>:payer, :order=>"to_bank_on DESC") do |t|
    t.column :number, :url=>{:action=>:incoming_payment}
    t.column :full_name, :through=>:payer, :url=>{:controller=>:relations, :action=>:entity}
    t.column :paid_on
    t.column :amount, :url=>{:action=>:incoming_payment}
    t.column :used_amount
    t.column :name, :through=>:mode
    t.column :check_number
    t.column :to_bank_on
    # t.column :label, :through=>:responsible
    t.column :number, :through=>:deposit, :url=>{:action=>:deposit}
    t.action :incoming_payment_update, :if=>"RECORD.deposit.nil\?"
    t.action :incoming_payment_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.used_amount.to_f<=0"
  end

  def incoming_payments
    session[:incoming_payment_state] = params[:state]||session[:incoming_payment_state]||"all"
    session[:incoming_payment_key]   = params[:key]||session[:incoming_payment_key]||""
  end
  manage :incoming_payments, :to_bank_on=>"Date.today", :paid_on=>"Date.today", :responsible_id=>"@current_user.id", :payer_id=>"(@current_company.entities.find(params[:payer_id]).id rescue 0)", :amount=>"params[:amount].to_f", :bank=>"params[:bank]", :account_number=>"params[:account_number]"

  create_kame(:incoming_payment_sales, :model=>:sales, :conditions=>["#{Sale.table_name}.company_id=? AND #{Sale.table_name}.id IN (SELECT expense_id FROM #{IncomingPaymentUse.table_name} WHERE payment_id=? AND expense_type=?)", ['@current_company.id'], ['session[:current_payment_id]'], Sale.name]) do |t|
    t.column :number, :url=>{:action=>:sale, :controller=>:management}
    t.column :description, :through=>:client, :url=>{:action=>:entity, :controller=>:relations}
    t.column :created_on
    t.column :pretax_amount
    t.column :amount
  end
  
  def incoming_payment
    return unless @incoming_payment = find_and_check(:incoming_payment)
    session[:current_payment_id] = @incoming_payment.id
    t3e :number=>@incoming_payment.number, :entity=>@incoming_payment.payer.full_name
  end


  
  
  def incoming_payment_use_create
    expense = nil
    if request.post?
      @incoming_payment_use = IncomingPaymentUse.new(params[:incoming_payment_use])
      if @incoming_payment_use.save
        redirect_to_back
      end
      expense = @incoming_payment_use.expense
#       unless incoming_payment = @current_company.incoming_payments.find_by_id(params[:incoming_payment_use][:payment_id])
#         @incoming_payment_use.errors.add(:payment_id, :required)
#         return
#       end
#       if incoming_payment.pay(expense, :downpayment=>params[:incoming_payment_use][:downpayment])
#         redirect_to_back
#       end
    else
      return unless expense = find_and_check(params[:expense_type], params[:expense_id])
      @incoming_payment_use = IncomingPaymentUse.new(:expense=>expense, :downpayment=>!expense.invoice?)
    end
    t3e :type=>expense.class.model_name.human, :number=>expense.number, :label=>expense.label
    render_form
  end

  def incoming_payment_use_delete
    # return unless @sale   = find_and_check(:sale, session[:current_sale_id])
    return unless @incoming_payment_use = find_and_check(:incoming_payment_use)
    if request.post? or request.delete?
      @incoming_payment_use.destroy #:action=>:sale, :step=>:summary, :id=>@sale.id
    end
    redirect_to_back
  end














  create_kame(:incoming_payment_modes, :conditions=>{:company_id=>['@current_company.id']}, :order=>:position) do |t|
    t.column :name
    t.column :with_accounting
    t.column :name, :through=>:cash, :url=>{:action=>:cash}
    t.column :with_deposit
    t.column :label, :through=>:depositables_account, :url=>{:controller=>:accountancy, :action=>:account}
    t.column :with_commission
    t.action :incoming_payment_mode_up, :method=>:post, :if=>"!RECORD.first\?"
    t.action :incoming_payment_mode_down, :method=>:post, :if=>"!RECORD.last\?"
    t.action :incoming_payment_mode_reflect, :method=>:post, :confirm=>:are_you_sure
    t.action :incoming_payment_mode_update
    t.action :incoming_payment_mode_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.destroyable\?"
  end
  def incoming_payment_modes
  end
  manage :incoming_payment_modes, :with_accounting=>"true"
  manage_list :incoming_payment_modes, :name

  
  def incoming_payment_mode_reflect
    return unless @incoming_payment_mode = find_and_check(:incoming_payment_mode)
    if request.post?
      for payment in  @incoming_payment_mode.unlocked_payments
        payment.update_attributes(:commission_account_id=>nil, :commission_amount=>nil)
      end
    end
    redirect_to :action=>:incoming_payment_modes
  end



  create_kame(:outgoing_payment_modes, :conditions=>{:company_id=>['@current_company.id']}, :order=>:position) do |t|
    t.column :name
    t.column :with_accounting
    t.column :name, :through=>:cash, :url=>{:action=>:cash}
    t.action :outgoing_payment_mode_up, :method=>:post, :if=>"!RECORD.first\?"
    t.action :outgoing_payment_mode_down, :method=>:post, :if=>"!RECORD.last\?"
    t.action :outgoing_payment_mode_update
    t.action :outgoing_payment_mode_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.destroyable\?"
  end
  def outgoing_payment_modes
  end
  manage :outgoing_payment_modes, :with_accounting=>"true"
  manage_list :outgoing_payment_modes, :name









  # manage :outgoing_payment_uses, :expense_id=>"(@current_company.purchases.find(params[:expense_id]).id rescue 0)"

  def outgoing_payment_use_create
    expense = nil
    if request.post?
      @outgoing_payment_use = OutgoingPaymentUse.new(params[:outgoing_payment_use])
      if @outgoing_payment_use.save
        redirect_to_back
      end
      expense = @outgoing_payment_use.expense
#       unless outgoing_payment = @current_company.outgoing_payments.find_by_id(params[:outgoing_payment_use][:payment_id])
#         @outgoing_payment_use.errors.add(:payment_id, :required)
#         return
#       end
#       if outgoing_payment.pay(expense, :downpayment=>params[:outgoing_payment_use][:downpayment])
#         redirect_to_back
#       end
    else
      return unless expense = find_and_check(:purchase, params[:expense_id])
      @outgoing_payment_use = OutgoingPaymentUse.new(:expense=>expense)
    end
    t3e :number=>expense.number
    render_form
  end

  def outgoing_payment_use_delete
    return unless @outgoing_payment_use = find_and_check(:outgoing_payment_use)
    if request.post? or request.delete?
      @outgoing_payment_use.destroy #:action=>:purchase_summary, :id=>@purchase.id
    end
    redirect_to_back
  end
  

  def self.outgoing_payments_conditions(options={})
    code = search_conditions(:outgoing_payments, :outgoing_payments=>[:amount, :used_amount, :check_number, :number], :entities=>[:code, :full_name])+"||=[]\n"
    code += "if session[:outgoing_payment_state] == 'undelivered'\n"
    code += "  c[0] += ' AND delivered=?'\n"
    code += "  c << false\n"
    code += "elsif session[:outgoing_payment_state] == 'waiting'\n"
    code += "  c[0] += ' AND to_bank_on > ?'\n"
    code += "  c << Date.today\n"
    code += "elsif session[:outgoing_payment_state] == 'unparted'\n"
    code += "  c[0] += ' AND used_amount != amount'\n"
    code += "end\n"
    code += "c\n"
    return code
  end

  # create_kame(:outgoing_payments, :conditions=>outgoing_payments_conditions, :joins=>"LEFT JOIN #{Entity.table_name} AS entities ON entities.id = payee_id", :order=>"to_bank_on DESC", :line_class=>"(RECORD.used_amount.zero? ? 'critic' : RECORD.unused_amount>0 ? 'warning' : '')") do |t|
  create_kame(:outgoing_payments, :conditions=>outgoing_payments_conditions, :joins=>:payee, :order=>"to_bank_on DESC", :line_class=>"(RECORD.used_amount.zero? ? 'critic' : RECORD.unused_amount>0 ? 'warning' : '')") do |t|
    t.column :number, :url=>{:action=>:outgoing_payment}
    t.column :full_name, :through=>:payee, :url=>{:action=>:entity, :controller=>:relations}
    t.column :paid_on
    t.column :amount, :url=>{:action=>:outgoing_payment}
    t.column :used_amount
    t.column :name, :through=>:mode
    t.column :check_number
    t.column :to_bank_on
    # t.column :label, :through=>:responsible
    t.action :outgoing_payment_update, :if=>"RECORD.updateable\?"
    t.action :outgoing_payment_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.destroyable\?"
  end

  def outgoing_payments
    session[:outgoing_payment_state] = params[:state]||session[:outgoing_payment_state]||"all"
    session[:outgoing_payment_key]   = params[:key]||session[:outgoing_payment_key]||""    
  end

  manage :outgoing_payments, :to_bank_on=>"Date.today", :paid_on=>"Date.today", :responsible_id=>"@current_user.id", :payee_id=>"(@current_company.entities.find(params[:payee_id]).id rescue 0)", :amount=>"params[:amount].to_f"


  create_kame(:outgoing_payment_purchases, :model=>:purchases, :conditions=>["#{Purchase.table_name}.company_id=? AND #{Purchase.table_name}.id IN (SELECT expense_id FROM #{OutgoingPaymentUse.table_name} WHERE payment_id=?)", ['@current_company.id'], ['session[:current_outgoing_payment_id]']]) do |t|
    t.column :number, :url=>{:action=>:purchase, :controller=>:management}
    t.column :description, :through=>:supplier, :url=>{:action=>:entity, :controller=>:relations}
    t.column :created_on
    t.column :pretax_amount
    t.column :amount
  end
  
  def outgoing_payment
    return unless @outgoing_payment = find_and_check(:outgoing_payment)
    session[:current_outgoing_payment_id] = @outgoing_payment.id
    t3e :number=>@outgoing_payment.number, :payee=>@outgoing_payment.payee.full_name
  end




  create_kame(:taxes, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :amount, :precision=>3
    t.column :nature_label
    t.column :included
    t.column :reductible
    t.column :label, :through=>:paid_account, :url=>{:controller=>:accountancy, :action=>:account}
    t.column :label, :through=>:collected_account, :url=>{:controller=>:accountancy, :action=>:account}
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
