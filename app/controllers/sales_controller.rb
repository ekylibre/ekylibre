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

  list(:credits, :model=>:sales, :conditions=>{:company_id=>['@current_company.id'], :origin_id=>['session[:current_sale_id]'] }, :children=>:lines) do |t|
    t.column :number, :url=>true, :children=>:designation
    t.column :full_name, :through=>:client, :children=>false
    t.column :created_on, :children=>false
    t.column :pretax_amount
    t.column :amount
  end

  list(:deliveries, :model=>:outgoing_deliveries, :children=>:lines, :conditions=>{:company_id=>['@current_company.id'], :sale_id=>['session[:current_sale_id]']}) do |t|
    t.column :number, :children=>:product_name
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
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :controller=>:finances
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

  list(:lines, :model=>:sale_lines, :conditions=>{:company_id=>['@current_company.id'], :sale_id=>['session[:current_sale_id]']}, :order=>:id, :export=>false) do |t|
    #t.column :name, :through=>:product
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

  list(:conditions=>sales_conditions, :joins=>:client, :order=>'created_on desc, number desc', :line_class=>'RECORD.state') do |t|
    t.column :number, :url=>{:action=>:show, :step=>:default}
    #t.column :name, :through=>:nature#, :url=>{:action=>:sale_nature}
    t.column :created_on
    t.column :label, :through=>:responsible
    t.column :full_name, :through=>:client, :url=>true
    # t.column :code, :through=>:client, :url=>{:controller=>:relations, :action=>:entity}, :label=>"client_code"
    t.column :comment
    t.column :state_label
    t.column :paid_amount
    t.column :amount
    t.action :show, :url=>{:format=>:pdf}, :image=>:print
    t.action :edit, :if=>'RECORD.draft? '
    t.action :cancel, :if=>'RECORD.cancelable? '
    t.action :destroy, :method=>:delete, :if=>'RECORD.aborted? ', :confirm=>:are_you_sure_you_want_to_delete
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

  def cancel
    return unless @sale = find_and_check(:sale)
    session[:sale_id] = @sale.id
    if request.post?
      lines = {}
      params[:sale_creditable_lines].select{|k,v| v[:validated].to_i == 1}.collect{|k, v| lines[k] = v[:quantity].to_f }
      if lines.empty?
        notify_error_now(:need_quantities_to_cancel_an_sale)
        return
      end
      if credit = @sale.cancel(lines, :responsible=>@current_user)
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
    return unless client = find_and_check(:entity)
    if request.xhr?
      session[:current_entity_id] = client.id
      cid = client.default_contact.id
      @sale = @current_company.sales.find_by_id(params[:sale_id])||Sale.new(:contact_id=>cid, :delivery_contact_id=>cid, :invoice_contact_id=>cid)
      render :partial=>'contacts_form', :locals=>{:client=>client}
    end

#     if @sale
#       client_id = @sale.client_id
#     else
#       client_id = params[:client_id]||(params[:sale]||{})[:client_id]||session[:current_entity_id]
#       client_id = 0 if client_id.blank?
#     end
#     client = @current_company.entities.find_by_id(client_id)
#     session[:current_entity_id] = client_id
#     @contacts = (client ? client.contacts.collect{|x| [x.address, x.id]} : [])
#     render :text=>options_for_select(@contacts) if request.xhr?
  end

  def correct
    return unless @sale = find_and_check(:sale)
    if request.post?
      @sale.correct
    end
    redirect_to :action=>:show, :step=>:products, :id=>@sale.id
  end

  def new
    if request.post?
      @sale = Sale.new(params[:sale])
      @sale.company_id = @current_company.id
      @sale.number = ''
      if @sale.save
        redirect_to :action=>:show, :step=>:products, :id=>@sale.id
      end
    else
      @sale = Sale.new
      if client = @current_company.entities.find_by_id(params[:client_id]||params[:entity_id]||session[:current_entity_id])
        cid = client.default_contact.id
        @sale.attributes = {:contact_id=>cid, :delivery_contact_id=>cid, :invoice_contact_id=>cid}
      end
      session[:current_entity_id] = (client ? client.id : nil)
      @sale.responsible_id = @current_user.id
      @sale.client_id = session[:current_entity_id]
      @sale.letter_format = false
      @sale.function_title = tg('letter_function_title')
      @sale.introduction = tg('letter_introduction')
      # @sale.conclusion = tg('letter_conclusion')
    end
    render_restfully_form
  end

  def create
    if request.post?
      @sale = Sale.new(params[:sale])
      @sale.company_id = @current_company.id
      @sale.number = ''
      if @sale.save
        redirect_to :action=>:show, :step=>:products, :id=>@sale.id
      end
    else
      @sale = Sale.new
      if client = @current_company.entities.find_by_id(params[:client_id]||params[:entity_id]||session[:current_entity_id])
        cid = client.default_contact.id
        @sale.attributes = {:contact_id=>cid, :delivery_contact_id=>cid, :invoice_contact_id=>cid}
      end
      session[:current_entity_id] = (client ? client.id : nil)
      @sale.responsible_id = @current_user.id
      @sale.client_id = session[:current_entity_id]
      @sale.letter_format = false
      @sale.function_title = tg('letter_function_title')
      @sale.introduction = tg('letter_introduction')
      # @sale.conclusion = tg('letter_conclusion')
    end
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
    if request.post?
      if copy = sale.duplicate(:responsible_id=>@current_user.id)
        redirect_to :action=>:show, :step=>:products, :id=>copy.id
        return
      end
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
    if request.post?
      if @sale.update_attributes(params[:sale])
        redirect_to :action=>:show, :step=>:products, :id=>@sale.id
        return
      end
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
    if request.post?
      if @sale.update_attributes(params[:sale])
        redirect_to :action=>:show, :step=>:products, :id=>@sale.id
        return
      end
    end
    t3e @sale.attributes
    render_restfully_form
  end

  # Displays the main page with the list of sales
  def index
    #raise Exception.new session[:sale_state].inspect
    session[:sale_state] ||= "all"
    @key = params[:key]||session[:sale_key]||""
    if request.post?
      #raise Exception.new params.inspect
      session[:sale_state] = params[:sale][:state]
      session[:sale_key] = @key
    end
  end

  def statistics
    session[:nb_year] = params[:nb_year]||2
    if params[:display]
      return unless product = find_and_check(:product, params[:product_id])
      session[:product_id] = product.id

      g = Gruff::Line.new('800x600')
      g.title = product.catalog_name.to_s
      g.title_font_size=20
      g.line_width = 2
      g.dot_radius = 2

      (params[:nb_year].to_i+1).times do |x|
        d = (Date.today - x.year) - 12.month
        sales=[]
        
        12.times do |m|
          sales << @current_company.sale_lines.sum(:quantity, :conditions=>['product_id=? and created_on BETWEEN ? AND ?', product.id, d.beginning_of_month, d.end_of_month], :joins=>"INNER JOIN #{Sale.table_name} AS s ON s.id=#{SaleLine.table_name}.sale_id").to_f
          d += 1.month
          g.labels[m] = d.month.to_s # t('date.abbr_month_names')[d.month].to_s
        end
        g.data('N'+(x>0 ? '-'+x.to_s : '').to_s, sales) # +d.year.to_s
      end

      dir = "#{Rails.root.to_s}/public/images/gruff/#{@current_company.code}"
      @graph = "management-statistics-#{product.code}-#{rand.to_s[2..-1]}.png"
      
      FileUtils.mkdir_p dir unless File.exists? dir
      g.write(dir+"/"+@graph)

    elsif params[:export]
      data = {}
      mode = (params[:mode]||:quantity).to_s.to_sym
      source = (params[:source]||:sales_invoices).to_s.to_sym
      states = [:invoice]
      states << :order if source == :sales
      query = "SELECT product_id, sum(sol.#{mode}) AS total FROM #{SaleLine.table_name} AS sol JOIN #{Sale.table_name} AS so ON (sol.sale_id=so.id) WHERE state IN ("+states.collect{|s| "'#{s}'"}.join(', ')+")  AND created_on BETWEEN ? AND ? GROUP BY product_id"
      start = (Date.today - params[:nb_years].to_i.year).beginning_of_month
      finish = Date.today.end_of_month
      date = start
      months = [] # [::I18n.t('activerecord.models.product')]
      # puts [start, finish].inspect
      while date <= finish
        # puts date.inspect
        # raise Exception.new(t('date.month_names').inspect)
        # period = '="'+t('date.month_names')[date.month]+" "+date.year.to_s+'"'
        period = '="'+date.year.to_s+" "+date.month.to_s+'"'
        months << period
        for product in @current_company.products.find(:all, :select=>"products.*, total", :joins=>ActiveRecord::Base.send(:sanitize_sql_array, ["LEFT JOIN (#{query}) AS sold ON (products.id=product_id)", date.beginning_of_month, date.end_of_month]), :order=>"product_id")
          data[product.id.to_s] ||= {}
          data[product.id.to_s][period] = product.total if product.total.to_f!=0
        end
        date += 1.month
      end

      csv_data = FasterCSV.generate do |csv|
        csv << [Product.model_name.human, Product.human_attribute_name('sales_account_id')]+months
        for product in @current_company.products.find(:all, :order=>"active DESC, name")
          valid = false
          data[product.id.to_s].collect do |k,v|
            valid = true unless v.nil? and  v != 0
          end
          if product.active or valid
            row = [product.name, (product.sales_account ? product.sales_account.number : "?")]
            months.size.times {|i| row << number_to_currency(data[product.id.to_s][months[i]], :separator=>',', :delimiter=>' ', :unit=>'', :precision=>2) }
            csv << row
          end
        end
      end
      
      send_data csv_data, :type=>Mime::CSV, :disposition=>'inline', :filename=>tl(source)+'.csv'
    end
  end

end
