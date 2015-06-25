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

class SalesController < ApplicationController

  # management -> sales_conditions
  def self.sales_conditions
    code = ""
    code = search_conditions(:sale, :sales=>[:pretax_amount, :amount, :number, :initial_number, :comment], :entities=>[:code, :full_name])+"||=[]\n"
    code += "unless session[:sale_state].blank?\n"
    code += "  if session[:sale_state] == 'current'\n"
    code += "    c[0] += \" AND state IN ('estimate', 'order', 'invoice')\"\n" 
    code += "  elsif session[:sale_state] == 'unpaid'\n"
    code += "    c[0] += \" AND state IN ('order', 'invoice') AND paid_amount < amount AND lost = ?\"\n"
    code += "    c << false\n"
    code += "  end\n "
    code += "  if session[:sale_responsible_id] > 0\n"
    code += "    c[0] += \" AND \#{Sale.table_name}.responsible_id = ?\"\n"
    code += "    c << session[:sale_responsible_id]\n"
    code += "  end\n"
    code += "end\n "
    code += "c\n "
    code
  end

  list(:conditions=>sales_conditions, :joins=>:client, :order=>'created_on desc, number desc', :line_class=>'RECORD.tags') do |t|
    t.column :number, :url=>{:action=>:show, :step=>:default}
    t.column :created_on
    t.column :invoiced_on
    t.column :label, :through=>:client, :url=>true
    t.column :label, :through=>:responsible
    t.column :comment
    t.column :state_label
    t.column :paid_amount
    t.column :amount
    t.action :show, :url=>{:format=>:pdf}, :image=>:print
    t.action :edit, :if=>'RECORD.draft? '
    t.action :cancel, :if=>'RECORD.cancelable? '
    t.action :destroy, :method=>:delete, :if=>'RECORD.aborted? ', :confirm=>:are_you_sure_you_want_to_delete
  end

  # Displays the main page with the list of sales
  def index
    session[:sale_state] = params[:s] ||= params[:s]||"all"
    session[:sale_key] = params[:q]
    session[:sale_responsible_id] = params[:responsible_id].to_i
    respond_to do |format|
      format.html
      format.pdf { render_print_sales(params[:established_on]||Date.today) }
    end
  end

  list(:credits, :model=>:sales, :conditions=>{:company_id=>['@current_company.id'], :origin_id=>['session[:current_sale_id]'] }, :children=>:lines) do |t|
    t.column :number, :url=>true, :children=>:designation
    t.column :full_name, :through=>:client, :children=>false
    t.column :created_on, :children=>false
    t.column :pretax_amount
    t.column :amount
  end

  list(:deliveries, :model=>:outgoing_deliveries, :children=>:lines, :conditions=>{:company_id=>['@current_company.id'], :sale_id=>['session[:current_sale_id]']}) do |t|
    t.column :number, :children=>:product_name
    t.column :last_name, :through=>:transporter, :children=>false, :url=>true
    t.column :address, :through=>:contact, :children=>false
    t.column :planned_on, :children=>false
    t.column :moved_on, :children=>false
    t.column :quantity, :datatype=>:decimal
    t.column :pretax_amount
    t.column :amount
    t.action :edit, :if=>'RECORD.sale.order? '
    t.action :destroy, :if=>'RECORD.sale.order? ', :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  list(:payment_uses, :model=>:incoming_payment_uses, :conditions=>["#{IncomingPaymentUse.table_name}.company_id=? AND #{IncomingPaymentUse.table_name}.expense_id=? AND #{IncomingPaymentUse.table_name}.expense_type=?", ['@current_company.id'], ['session[:current_sale_id]'], Sale.name]) do |t|
    t.column :number, :through=>:payment, :url=>true
    t.column :amount, :through=>:payment, :label=>"payment_amount", :url=>true
    t.column :amount
    t.column :payment_way
    t.column :scheduled, :through=>:payment, :datatype=>:boolean, :label=>:column
    t.column :downpayment
    # t.column :paid_on, :through=>:payment, :label=>:column, :datatype=>:date
    t.column :to_bank_on, :through=>:payment, :label=>:column, :datatype=>:date
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  list(:subscriptions, :conditions=>{:company_id=>['@current_company.id'], :sale_id=>['session[:current_sale_id]']}) do |t|
    t.column :number
    t.column :name, :through=>:nature
    t.column :full_name, :through=>:entity, :url=>true
    t.column :address, :through=>:contact
    t.column :start
    t.column :finish
    t.column :quantity
    t.action :edit
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  list(:undelivered_lines, :model=>:sale_lines, :conditions=>{:company_id=>['@current_company.id'], :sale_id=>['session[:current_sale_id]'], :reduction_origin_id=>nil}) do |t|
    t.column :name, :through=>:product
    t.column :pretax_amount, :through=>:price
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :pretax_amount
    t.column :amount
    t.column :undelivered_quantity, :datatype=>:decimal
  end

  list(:lines, :model=>:sale_lines, :conditions=>{:company_id=>['@current_company.id'], :sale_id=>['session[:current_sale_id]']}, :order=>:position, :export=>false, :line_class=>"((RECORD.product.subscription? and RECORD.subscriptions.sum(:quantity) != RECORD.quantity) ? 'warning' : '')", :include=>[:product, :subscriptions]) do |t|
    #t.column :name, :through=>:product
    t.column :position
    t.column :label
    t.column :annotation
    t.column :serial, :through=>:tracking, :url=>true
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :pretax_amount, :through=>:price, :label=>"unit_price_amount"
    t.column :pretax_amount
    t.column :amount
    t.action :edit, :if=>'RECORD.sale.draft? and RECORD.reduction_origin_id.nil? '
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>'RECORD.sale.draft? and RECORD.reduction_origin_id.nil? '
  end

  # Displays details of one sale selected with +params[:id]+
  def show
    return unless @sale = find_and_check(:sale)
    respond_to do |format|
      format.html do
        session[:current_sale_id] = @sale.id
        if params[:step] and not ["products", "deliveries", "summary"].include? params[:step]
          state  = @sale.state
          params[:step] = (@sale.invoice? ? :summary : @sale.order? ? :deliveries : :products).to_s
        end
        if params[:step] == "deliveries"
          if @sale.deliveries.size <= 0 and @sale.order? and @sale.has_content?
            redirect_to :controller=>:outgoing_deliveries, :action=>:new, :sale_id=>@sale.id
          elsif @sale.deliveries.size <= 0 and @sale.invoice?
            notify(:sale_already_invoiced)
          elsif @sale.lines.size <= 0
            notify_warning(:no_lines_found)
            redirect_to :action=>:show, :step=>:products, :id=>@sale.id
          end
        end
        t3e @sale.attributes, :client=>@sale.client.full_name, :state=>@sale.state_label, :label=>@sale.label
      end
      format.xml { render :xml => @sale.to_xml }
      format.pdf do
        if @sale.invoice?
          render_print_sales_invoice(@sale)
        else
          render_print_sales_order(@sale)
        end
      end
    end

  end

  def abort
    return unless @sale = find_and_check(:sale)
    if request.post?
      @sale.abort
    end
    redirect_to :action=>:show, :id=>@sale.id
  end


  list(:creditable_lines, :model=>:sale_lines, :conditions=>["sale_id=? AND reduction_origin_id IS NULL", ['session[:sale_id]']]) do |t|
    t.column :label
    t.column :annotation
    t.column :name, :through=>:product
    t.column :amount, :through=>:price, :label=>:column
    t.column :quantity
    t.column :credited_quantity, :datatype=>:decimal
    t.check_box  :validated, :value=>"true", :label=>'OK'
    t.text_field :quantity, :value=>"RECORD.uncredited_quantity", :size=>6
  end

  def cancel
    return unless @sale = find_and_check(:sale)
    session[:sale_id] = @sale.id
    if request.post?
      lines = {}
      params[:creditable_lines].select{|k,v| v[:validated].to_i == 1}.collect{ |k, v| lines[k] = v[:quantity].to_f }
      if lines.empty?
        notify_error_now(:need_quantities_to_cancel_an_sale)
        return
      end
      responsible = @current_company.employees.find_by_id(params[:sale][:responsible_id]) if params[:sale]
      if credit = @sale.cancel(lines, :responsible=>responsible||@current_user)
        redirect_to :action=>:show, :id=>credit.id
      end
    end
    t3e @sale.attributes
  end

  def confirm
    return unless @sale = find_and_check(:sale)
    if request.post?
      @sale.confirm
    end
    redirect_to :action=>:show, :step=>:deliveries, :id=>@sale.id
  end

  def contacts
    if request.xhr?
      client, contact_id = nil, nil
      client = if params[:selected] and contact = @current_company.contacts.find_by_id(params[:selected])
                 contact.entity
               else
                 @current_company.entities.find_by_id(params[:client_id])
               end
      if client
        session[:current_entity_id] = client.id
        contact_id = (contact ? contact.id : client.default_contact.id)
      end
      @sale = @current_company.sales.find_by_id(params[:sale_id])||Sale.new(:contact_id=>contact_id, :delivery_contact_id=>contact_id, :invoice_contact_id=>contact_id)
      render :partial=>'contacts_form', :locals=>{:client=>client}
    else
      redirect_to :action=>:index
    end
  end

  def correct
    return unless @sale = find_and_check(:sale)
    if request.post?
      @sale.correct
    end
    redirect_to :action=>:show, :step=>:products, :id=>@sale.id
  end

  def new
    @sale = Sale.new
    if client = @current_company.entities.find_by_id(params[:client_id]||params[:entity_id]||session[:current_entity_id])
      if client.default_contact
        cid = client.default_contact.id 
        @sale.attributes = {:contact_id=>cid, :delivery_contact_id=>cid, :invoice_contact_id=>cid}
      end
    end
    session[:current_entity_id] = (client ? client.id : nil)
    @sale.responsible_id = @current_user.id
    @sale.client_id = session[:current_entity_id]
    @sale.letter_format = false
    @sale.function_title = tg('letter_function_title')
    @sale.introduction = tg('letter_introduction')
    # @sale.conclusion = tg('letter_conclusion')
    render_restfully_form
  end

  def create
    @sale = Sale.new(params[:sale])
    @sale.company_id = @current_company.id
    @sale.number = ''
    return if save_and_redirect(@sale, :url=>{:action=>:show, :step=>:products, :id=>"id"})
    render_restfully_form
  end

  def destroy
    return unless @sale = find_and_check(:sale)
    if request.post? or request.delete?
      if @sale.aborted?
        @sale.destroy
      else
        notify_error(:sale_cant_be_deleted)
      end
    end
    redirect_to_current
  end

  def duplicate
    return unless sale = find_and_check(:sale)
    copy = nil
    begin
      copy = sale.duplicate(:responsible_id=>@current_user.id)
    rescue Exception => e
      notify_error(:exception_raised, :message=>e.message)
    end
    if copy
      redirect_to :action=>:show, :step=>:products, :id=>copy.id
      return
    end
    redirect_to_current
  end

  def invoice
    return unless @sale = find_and_check(:sale)
    if request.post?
      ActiveRecord::Base.transaction do
        raise ActiveRecord::Rollback unless @sale.invoice
        redirect_to :action=>:show, :step=>:summary, :id=>@sale.id
        return
      end
    end
    redirect_to :action=>:show, :step=>:products, :id=>@sale.id
  end

  def propose
    return unless @sale = find_and_check(:sale)
    if request.post?
      @sale.propose
    end
    redirect_to :action=>:show, :step=>:products, :id=>@sale.id
  end

  def propose_and_invoice
    return unless @sale = find_and_check(:sale)
    if request.post?
      ActiveRecord::Base.transaction do
        raise ActiveRecord::Rollback unless @sale.propose
        raise ActiveRecord::Rollback unless @sale.confirm
        raise ActiveRecord::Rollback unless @sale.deliver
        raise ActiveRecord::Rollback unless @sale.invoice
      end
    end
    redirect_to :action=>:show, :step=>:summary, :id=>@sale.id
  end

  def refuse
    return unless @sale = find_and_check(:sale)
    if request.post?
      @sale.refuse
    end
    redirect_to :action=>:show, :step=>:products, :id=>@sale.id
  end

  def edit
    return unless @sale = find_and_check(:sale)
    unless @sale.draft?
      notify_error(:sale_cannot_be_updated)
      redirect_to :action=>:show, :step=>:products, :id=>@sale.id
      return
    end
    t3e @sale.attributes
    render_restfully_form
  end

  def update
    return unless @sale = find_and_check(:sale)
    unless @sale.draft?
      notify_error(:sale_cannot_be_updated)
      redirect_to :action=>:show, :step=>:products, :id=>@sale.id
      return
    end
    if @sale.update_attributes(params[:sale])
      redirect_to :action=>:show, :step=>:products, :id=>@sale.id
      return
    end
    t3e @sale.attributes
    render_restfully_form
  end


  def statistics
    data = {}
    params[:states] ||= {}
    mode = params[:mode] = (params[:mode]||:pretax_amount).to_s.to_sym
    source = params[:source] = (params[:source]||:sales_invoices).to_s.to_sym
    if params[:export] == "sales"
      states = [:invoice]
      states << :order if source == :sales
      query = "SELECT product_id, sum(sol.#{mode}) AS total FROM #{SaleLine.table_name} AS sol JOIN #{Sale.table_name} AS so ON (sol.sale_id=so.id) WHERE "
      if params[:invoices].to_i > 0
        query << "state='invoice' AND invoiced_on BETWEEN ? AND ? "
      else
        query << "(state IS NULL"
        unless params[:states].empty?
          query << " OR state IN ("+params[:states].collect{|k,v| "'#{k.to_s.ascii}'"}.join(', ')+")"
        end
        query << ") AND created_on BETWEEN ? AND ? "
      end
      query << " GROUP BY product_id"
      start = (Date.today - params[:nb_years].to_i.year).beginning_of_month
      finish = Date.today.end_of_month
      date = start
      months = [] # [::I18n.t('activerecord.models.product')]
      # puts [start, finish].inspect
      while date <= finish
        period = '="'+t('date.abbr_month_names')[date.month]+" "+date.year.to_s+'"'
        months << period
        for product in @current_company.products.find(:all, :select=>"products.*, total", :joins=>ActiveRecord::Base.send(:sanitize_sql_array, ["LEFT JOIN (#{query}) AS sold ON (products.id=product_id)", date.beginning_of_month, date.end_of_month]), :order=>"product_id")
          data[product.id.to_s] ||= {}
          data[product.id.to_s][period] = product.total.to_f
        end
        date += 1.month
      end
      
      csv_data = Ekylibre::CSV.generate do |csv|
        csv << [Product.model_name.human, Product.human_attribute_name('code'), Product.human_attribute_name('sales_account_id')]+months
        for product in @current_company.products.find(:all, :order=>"name")
          valid = false
          for period, amount in data[product.id.to_s]
            valid = true if amount != 0
          end
          if product.active or valid
            row = [product.name, product.code, (product.sales_account ? product.sales_account.number : "?")]
            months.size.times do |i| 
              if data[product.id.to_s][months[i]].zero?
                row << ''
              else
                row << number_to_currency(data[product.id.to_s][months[i]], :separator=>',', :delimiter=>' ', :unit=>'', :precision=>2)
              end
            end
            csv << row
          end
        end
      end
      
      send_data csv_data, :type=>Mime::CSV, :disposition=>'inline', :filename=>tl(source)+'.csv'
    end
  end

end
