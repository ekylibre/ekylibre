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


class ManagementController < ApplicationController
  
  include ActionView::Helpers::FormOptionsHelper
  include ActionView::Helpers::NumberHelper
 
  def index
    @deliveries = @current_company.outgoing_deliveries.find(:all,:conditions=>{:moved_on=>nil})
    @purchases = @current_company.purchase_orders.find(:all, :conditions=>{:moved_on=>nil})
    all_stocks = @current_company.stocks
    @warehouses = @current_company.warehouses
    @stocks = []
    for stock in all_stocks
      @stocks << stock if stock.state == "critic"
    end
    @stock_transfers = @current_company.stock_transfers.find(:all, :conditions=>{:moved_on=>nil}) 
    @payments_to_deposit = @current_company.payments_to_deposit
    @deposits_to_lock = @current_company.deposits_to_lock
  end
  
  
  create_kame(:delays, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name, :url=>{:action=>:delay}
    t.column :active
    t.column :expression
    t.column :comment
    t.action :delay_update
    t.action :delay_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  def delays
  end

  def delay
    return unless @delay = find_and_check(:delay)
    t3e @delay.attributes
  end

  manage :delays
  

  #this method allows to create a graphism
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
          sales << @current_company.sales_order_lines.sum(:quantity, :conditions=>['product_id=? and created_on BETWEEN ? AND ?', product.id, d.beginning_of_month, d.end_of_month], :joins=>"INNER JOIN #{SalesOrder.table_name} AS s ON s.id=#{SalesOrderLine.table_name}.order_id").to_f
          d += 1.month
          g.labels[m] = d.month.to_s # t('date.abbr_month_names')[d.month].to_s
        end
        g.data('N'+(x>0 ? '-'+x.to_s : '').to_s, sales) # +d.year.to_s
      end

      dir = "#{Rails.root.to_s}/public/images/gruff/#{@current_company.code}"
      @graph = "management-statistics-#{product.code}-#{rand.to_s[2..-1]}.png"
      
      File.makedirs dir unless File.exists? dir
      g.write(dir+"/"+@graph)

    elsif params[:export]
      data = {}
      mode = (params[:mode]||:quantity).to_s.to_sym
      source = (params[:source]||:sales_invoices).to_s.to_sym
      query = if source == :sales_invoices
                "SELECT product_id, sum(sol.#{mode}) AS total FROM #{SalesInvoiceLine.table_name} AS sol JOIN #{SalesInvoice.table_name} AS so ON (sol.sales_invoice_id=so.id) WHERE created_on BETWEEN ? AND ? GROUP BY product_id"
              else
                "SELECT product_id, sum(sol.#{mode}) AS total FROM #{SalesOrderLine.table_name} AS sol JOIN #{SalesOrder.table_name} AS so ON (sol.order_id=so.id) WHERE state != 'E' AND created_on BETWEEN ? AND ? GROUP BY product_id"
              end
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
    
  #

  # Generic method to produce units of product
  def product_units
    return unless @product = find_and_check(:product)
    render :inline=>"<%=options_for_select(@product.units.collect{|x| [x.name, x.id]})-%>"
  end

  def product_trackings
    return unless @product = find_and_check(:product)
    render :inline=>"<%=options_for_select([['---', '']]+@product.trackings.collect{|x| [x.name, x.id]})-%>"
  end



  create_kame(:inventories, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :created_on
    t.column :changes_reflected
    t.column :label, :through=>:responsible, :url=>{:controller=>:company, :action=>:user}
    t.column :comment
    t.action :print, :url=>{:controller=>:company, :p0=>"RECORD.id", :id=>:inventory}
    t.action :inventory_reflect, :if=>'RECORD.company.inventories.find_all_by_changes_reflected(false).size <= 1 and !RECORD.changes_reflected', :image=>"action", :confirm=>:are_you_sure
    t.action :inventory_update,  :if=>'!RECORD.changes_reflected'
    t.action :inventory_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>'RECORD.changes_reflected == false'
  end

  create_kame(:inventory_lines_create, :model=>:stocks, :conditions=>{:company_id=>['@current_company.id'] }, :per_page=>1000, :order=>'warehouse_id') do |t|
    t.column :name, :through=>:warehouse, :url=>{:action=>:warehouse}
    t.column :name, :through=>:product, :url=>{:action=>:product}
    t.column :name, :through=>:tracking, :url=>{:action=>:tracking}
    t.column :quantity, :precision=>3
    t.column :label, :through=>:unit
    t.text_field :quantity
  end

  create_kame(:inventory_lines_update, :model=>:inventory_lines, :conditions=>{:company_id=>['@current_company.id'], :inventory_id=>['session[:current_inventory]'] }, :per_page=>1000,:order=>'warehouse_id') do |t|
    t.column :name, :through=>:warehouse, :url=>{:action=>:warehouse}
    t.column :name, :through=>:product, :url=>{:action=>:product}
    t.column :name, :through=>:tracking, :url=>{:action=>:tracking}
    t.column :theoric_quantity, :precision=>3
    t.text_field :quantity
  end

  def inventories
    if @current_company.stockable_products.size <= 0
      notify(:need_stocks_to_create_inventories, :now)
    end    
  end
  
  def inventory_create
    if @current_company.stockable_products.size <= 0
      notify(:need_stocks_to_create_inventories, :warning)
      redirect_to_back
    end
    notify(:validates_old_inventories, :warning, :now) if @current_company.inventories.find_all_by_changes_reflected(false).size >= 1
    @inventory = Inventory.new(:responsible_id=>@current_user.id)
    if request.post?
      @inventory = Inventory.new(params[:inventory])
      params[:inventory_lines_create].each{|k,v| v[:stock_id]=k}
      # raise Exception.new(params[:inventory_lines_create].inspect)
      @inventory.company_id = @current_company.id
      if @inventory.save
        @inventory.set_lines(params[:inventory_lines_create].values)
      end
      redirect_to :action=>:inventories
    end
  end

  def inventory_reflect
    return unless @inventory = find_and_check(:inventories)
    if @inventory.reflect_changes
      notify(:changes_have_been_reflected, :success)
    else
      notify(:changes_have_not_been_reflected, :error)
    end
    redirect_to :action=>:inventories 
  end

  def inventory_update
    return unless @inventory = find_and_check(:inventories)
    session[:current_inventory] = @inventory.id
    if request.post? and !@inventory.changes_reflected
      if @inventory.update_attributes(params[:inventory])
        # @inventory.set_lines(params[:inventory_lines_create].values)
        for id, attributes in params[:inventory_lines_update]
          il = @current_company.inventory_lines.find_by_id(id).update_attributes!(attributes) 
        end
      end
      redirect_to :action=>:inventories
    end
  end

  def inventory_delete
    return unless @inventory = find_and_check(:inventories)
    if request.post? and !@inventory.changes_reflected
      @inventory.destroy
    end
    redirect_to_current
  end
  
  def self.sales_invoices_conditions
    code = ""
    code = search_conditions(:sales_invoices, :sales_invoices=>[:number, :amount, :amount_with_taxes], :e=>[:full_name, :code], :s=>[:number])+"||=[]\n"
    code += "unless session[:sales_invoice_state].blank? \n"
    code += "  if session[:sales_invoice_state] == 'credits' \n"
    code += "    c[0] += \" AND credit = true \"\n"
    code += "  elsif session[:sales_invoice_state] == 'cancelled' \n"
    code += "    c[0] += \" AND sales_invoices.id IN (SELECT origin_id FROM #{SalesInvoice.table_name} WHERE credit = true AND company_id=\#\{@current_company.id\})\" \n"
    code += "  end\n "
    code += "end\n "
    code += "c \n"
    code
  end
  
  create_kame(:sales_invoices, :conditions=>sales_invoices_conditions, :line_class=>'RECORD.status', :joins=>"LEFT JOIN #{Entity.table_name} e ON e.id = #{SalesInvoice.table_name}.client_id LEFT JOIN #{SalesOrder.table_name} AS s ON s.id = #{SalesInvoice.table_name}.sales_order_id", :order=>"#{SalesInvoice.table_name}.created_on DESC, #{SalesInvoice.table_name}.number DESC") do |t|
    t.column :number, :url=>{:action=>:sales_invoice}
    t.column :full_name, :through=>:client, :url=>{:controller=>:relations, :action=>:entity}
    t.column :number, :through=>:sales_order, :url=>{:action=>:sales_order}
    t.column :created_on
    t.column :amount
    t.column :amount_with_taxes
    t.column :credit
    #t.action :sales_invoice_to_accountancy
    t.action :print, :url=>{:controller=>:company, :p0=>"RECORD.id", :id=>:sales_invoice}
    
    t.action :sales_invoice_cancel, :if=>"RECORD.creditable\?"
  end


  def sales_invoices
    @key = params[:key]||session[:sales_invoice]||""
    session[:sales_invoice_state] ||= "all"
    if request.post?
      session[:sales_invoice_state] = params[:sales_invoice][:state]
      session[:sales_invoice_key] = @key
    end
  end

  
  #
  # def sales_invoice_to_accountancy
#     @sales_invoice = find_and_check(:sales_invoice)
#     @sales_invoice.to_accountancy
#     redirect_to :action=>:sales_invoices
#   end


  create_kame(:credit_lines, :model=>:sales_invoice_lines, :conditions=>{:sales_invoice_id=>['session[:sales_invoice_id]']}) do |t|
    t.column :name, :through=>:product
    t.column :amount_with_taxes, :through=>:price, :label=>:column
    t.column :quantity
    t.column :credited_quantity, :datatype=>:decimal
    t.check_box  :validated, :value=>"true", :label=>'OK'
    t.text_field :quantity, :value=>"RECORD.uncredited_quantity", :size=>6
  end

  def sales_invoice_cancel
    return unless @sales_invoice = find_and_check(:sales_invoices)
    session[:sales_invoice_id] = @sales_invoice.id
#    @sales_invoice_cancel = SalesInvoice.find_by_origin_id_and_company_id(@sales_invoice.id, @current_company.id)
#     if @sales_invoice_cancel.nil?
#       @sales_invoice_cancel = SalesInvoice.new(:origin_id=>@sales_invoice.id, :client_id=>@sales_invoice.client_id, :credit=>true, :company_id=>@current_company.id)
#       @sales_invoice_cancel_lines = @sales_invoice.lines.collect{|x| SalesInvoiceLine.new(:origin_id=>x.id, :product_id=>x.product_id, :price_id=>x.price_id, :quantity=>0, :company_id=>@current_company.id, :order_line_id=>x.order_line_id)}
#     else
#       @sales_invoice_cancel_lines = @sales_invoice_cancel.lines
#     end
    if request.post?
      ActiveRecord::Base.transaction do
        # session[:errors] = []
        params[:credit_lines] ||= {}
        @credit = SalesInvoice.new(:origin_id=>@sales_invoice.id, :client_id=>@sales_invoice.client_id, :credit=>true, :company_id=>@current_company.id)
        saved = @credit.save
        if saved
          for line in @sales_invoice.lines
            if params[:credit_lines][line.id.to_s]
              if params[:credit_lines][line.id.to_s][:validated].to_i == 1
                # raise Exception.new [params[:credit_lines], 0-params[:credit_lines][line.id.to_s][:quantity].to_f].inspect
                quantity = 0-params[:credit_lines][line.id.to_s][:quantity].to_f
                puts ">>>>>>>>>>>>>>>>>>>>>>>>> "+quantity.to_s
                if quantity != 0.0
                  puts ">>>>>>>>>>>>>>>>><>>>>>>>>>>>>>>>>>>>>>> "+quantity.to_s
                  credit_line = @credit.lines.create(:quantity=>quantity, :origin_id=>line.id, :product_id=>line.product_id, :price_id=>line.price_id, :company_id=>line.company_id, :order_line_id=>line.order_line_id)
                  unless credit_line.save
                    saved = false
                    # session[:errors] << credit_line.errors.full_messages
                    @credit.errors.add_from_record(credit_line)
                  end
                  puts ">>>>>>>>>>>>>>>>><>>>>>>>>>>>>>>>>>>>>>> "+@credit.inspect
                end
              end
            end
          end
          
          if @credit.reload.amount_with_taxes == 0
            puts @credit.inspect
            notify(:need_quantities_to_cancel_an_sales_invoice, :error)
            raise ActiveRecord::Rollback 
          end

#           for cancel_line in @sales_invoice_cancel_lines
#             cancel_line.quantity -= (params[:sales_invoice_cancel_line][cancel_line.origin_id.to_s][:quantity].to_f)
#             cancel_line.sales_invoice_id = @sales_invoice_cancel.id
#             saved = false unless cancel_line.save
#           end
        end
        if saved
          if @current_company.preference('accountancy.accountize.automatic')
            @credit.to_accountancy if @current_company.preference('accountancy.accountize.automatic').value == true
          end

          redirect_to :action=>:sales_invoice, :id=>@credit.id
        else
#           session[:errors] = []
#           for line in @sales_invoice_cancel_lines
#             session[:errors] << line.errors.full_messages if !line.errors.full_messages.empty?
#           end
          # redirect_to :action=>:sales_invoice_cancel, :id=>@sales_invoice.id
          raise ActiveRecord::Rollback
        end
      end
    end
    t3e @sales_invoice.attributes
  end
   

  create_kame(:sales_invoice_lines, :conditions=>{:company_id=>['@current_company.id'], :sales_invoice_id=>['session[:current_sales_invoice]']}) do |t|
    t.column :name, :through=>:product, :url=>{:action=>:product}
    t.column :amount, :through=>:price
    t.column :amount_with_taxes, :through=>:price, :label=>:column
    t.column :quantity
    t.column :amount
    t.column :amount_with_taxes
  end

  create_kame(:sales_invoice_credits, :model=>:sales_invoices, :conditions=>{:company_id=>['@current_company.id'], :origin_id=>['session[:current_sales_invoice]'] }, :children=>:lines) do |t|
    t.column :number, :url=>{:action=>:sales_invoice}, :children=>:designation
    t.column :full_name, :through=>:client, :children=>false
    t.column :created_on, :children=>false
    t.column :amount
    t.column :amount_with_taxes
  end


  def sales_invoice
    return unless @sales_invoice = find_and_check(:sales_invoice)
    session[:current_sales_invoice] = @sales_invoice.id
    t3e :nature=>tc(@sales_invoice.credit ? :credit : :sales_invoice), :number=>@sales_invoice.number
  end

  def self.prices_conditions(options={})
    code = "conditions=[]\n"
    code += "if session[:entity_id] == 0 \n " 
    code += " conditions = ['company_id = ? AND active = ?', @current_company.id, true] \n "
    code += "else \n "
    code += " conditions = ['company_id = ? AND entity_id = ? AND active = ?', @current_company.id, session[:entity_id], true]"
    code += "end \n "
    code += "conditions \n "
    code
  end
  
  create_kame(:prices, :conditions=>prices_conditions) do |t|
    t.column :name, :through=>:product, :url=>{:action=>:product}
    t.column :full_name, :through=>:entity, :url=>{:controller=>:relations, :action=>:entity}
    t.column :name, :through=>:category, :url=>{:controller=>:relations, :action=>:entity_category}
    t.column :amount
    t.column :amount_with_taxes
    t.column :by_default
    # t.column :range
    t.action :price_update
    t.action :price_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end
  
  
  def prices
    @modes = ['all', 'clients', 'suppliers']
    @suppliers = @current_company.entities.find(:all, :conditions=>{:supplier=>true})
    session[:entity_id] = 0
    if request.post?
      mode = params[:price][:mode]
      if mode == "suppliers"
        session[:entity_id] = params[:price][:supply].to_i
      elsif mode == "clients"
        session[:entity_id] = @current_company.entity_id
      else
        session[:entity_id] = 0
      end
    end
  end
  
  def price_create
    @mode = (params[:mode]||"sales").to_sym 
    if request.post? 
      @price = @current_company.prices.new(params[:price])
      @price.entity_id = params[:price][:entity_id]||@current_company.entity_id
      return if save_and_redirect(@price)
    else
      @price = Price.new(:product_id=>params[:product_id], :category_id=>params[:entity_category_id]||session[:current_entity_category_id]||0)
      @price.entity_id = params[:entity_id] if params[:entity_id]
    end
    render_form    
  end

  def price_update
    return unless @price = find_and_check(:price)
    @mode = "purchases" if @price.entity_id != @current_company.entity_id
    if request.post?
      @price.amount_with_taxes = 0
      return if save_and_redirect(@price, :attributes=>params[:price])
    end
    t3e @price.attributes, :product=>@price.product.name
    render_form
  end
  
  def price_delete
    return unless @price = find_and_check(:price)
    if request.post? or request.delete?
      @price.update_attributes(:active=>false)
    end
    redirect_to_current
  end
  

  def prices_export
    @products = @current_company.available_products
    @entity_categories = @current_company.entity_categories
    
    csv = ["",""]
    csv2 = ["Code Produit", "Nom"]
    @entity_categories.each do |category|
      csv += [category.code, category.name, ""]
      csv2 += ["HT","TTC","TVA"]
    end
    
    csv_string = FasterCSV.generate_line(csv)
    csv_string += FasterCSV.generate_line(csv2)
    
    csv_string += FasterCSV.generate do |csv|
      
      @products.each do |product|
        line = []
        line << [product.code, product.name]
        @entity_categories.each do |category|
          price = @current_company.prices.find(:first, :conditions=>{:active=>true,:product_id=>product.id, :category_id=>EntityCategory.find_by_code_and_company_id(category.code, @current_company.id).id})
          #raise Exception.new price.inspect
          if price.nil?
            line << ["","",""]
          else
            line << [price.amount.to_s.gsub(/\./,","), price.amount_with_taxes.to_s.gsub(/\./,","), price.tax.amount]
          end
        end
        csv << line.flatten
      end
      
    end
    
    send_data csv_string,                                       
    :type => 'text/csv; charset=iso-8859-1; header=present',
    :disposition => "attachment; filename=Tarifs.csv"
    
  end
  
  def prices_import
    
    if request.post?
      if params[:csv_file].nil?
        notify(:you_must_select_a_file_to_import, :warning)
        redirect_to :action=>:prices_import
      else
        file = params[:csv_file][:path]
        name = "MES_TARIFS.csv"
        @entity_categories = []
        @available_prices = []
        @unavailable_prices = []
        i = 0
        File.open("#{Rails.root.to_s}/#{name}", "w") { |f| f.write(file.read)}
        FasterCSV.foreach("#{Rails.root.to_s}/#{name}") do |row|
          if i == 0
            x = 2
            while !row[x].nil?
              entity_category = EntityCategory.find_by_code_and_company_id(row[x], @current_company.id)
              entity_category = EntityCategory.create!(:code=>row[x], :name=>row[x+1], :company_id=>@current_company.id) if entity_category.nil?
              @entity_categories << entity_category
              x += 3
            end
          end
          
          if i > 1
            puts i.to_s+"hhhhhhhhhhhhhhh"
            x = 2
            @product = Product.find_by_code_and_company_id(row[0], @current_company.id)
            for category in @entity_categories
              blank = true
              tax = Tax.find(:first, :conditions=>{:company_id=>@current_company.id, :amount=>row[x+2].to_s.gsub(/\,/,".").to_f})
              tax_id = tax.nil? ? nil : tax.id
              @price = Price.find(:first, :conditions=>{:product_id=>@product.id,:company_id=>@current_company.id, :category_id=>category.id, :active=>true} )
              #raise Exception.new row.inspect+@price.inspect+@product.id.inspect+@current_company.id.inspect+category.id.inspect if i==5
              if @price.nil? and (!row[x].nil? or !row[x+1].nil? or !row[x+2].nil?)
                @price = Price.new(:amount=>row[x].to_s.gsub(/\,/,".").to_f, :tax_id=>tax_id, :amount_with_taxes=>row[x+1].to_s.gsub(/\,/,".").to_f, :company_id=>@current_company.id, :product_id=>@product.id, :category_id=>category.id, :entity_id=>@current_company.entity_id,:currency_id=>@current_company.currencies[0].id)
                blank = false
              elsif !@price.nil?
                blank = false
                @price.amount = row[x].to_s.gsub(/\,/,".").to_f
                @price.amount_with_taxes = row[x+1].to_s.gsub(/\,/,".").to_f
                @price.tax_id = tax_id
              end
              if blank == false
                if @price.valid?
                  @available_prices << @price
                else
                  @unavailable_prices << [i+1, @price.errors.full_messages]
                end
              end
              x += 3
            end
          end
          for price in @available_prices
            puts price.inspect+"    id" if price.id.nil? if i==14
          end
          #raise Exception.new @unavailable_prices.inspect if i == 12
          i += 1
        end

        if @unavailable_prices.empty?
          for price in @available_prices
            if price.id.nil?
              puts price.inspect
              Price.create!(price.attributes)
            else
              price.update_attributes(price.attributes)
            end
            notify(:prices_import_succeeded, :now)
          end
        end
      end
    end
    
  end
  
  create_kame(:product_prices, :conditions=>{:company_id=>['@current_company.id'], :product_id=>['session[:product_id]'], :active=>true}, :model=>:prices) do |t|
    t.column :name, :through=>:entity, :url=>{:controller=>:relations, :action=>:entity}
    t.column :name, :through=>:category, :url=>{:controller=>:relations, :action=>:entity_category}
    t.column :amount
    t.column :amount_with_taxes
    t.column :by_default
    # t.column :range
    t.action :price_update
    t.action :price_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  create_kame(:product_components, :conditions=>{:company_id=>['@current_company.id'], :product_id=>['session[:product_id]'], :active=>true}) do |t|
    t.column :name
    t.action :product_component_update
    t.action :product_component_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  def product_component_create
    return unless @product = find_and_check(:products, params[:product_id]||session[:product_id])
    if request.post?
      @product_component = ProductComponent.new(params[:product_component])
      @product_component.company_id = @current_company.id
      @product_component.product_id = @product.id
      return if save_and_redirect(@product_component, :url=>{:action=>:product, :id=>@product_component.product_id})
    else
      @product_component = ProductComponent.new(:quantity=>1.0)
    end
    t3e :product=>@product.name
    render_form
  end
  
  def product_component_update
    return unless @product_component = find_and_check(:product_component)
    @product = @product_component.product
    if request.post?
      @product_component.attributes = params[:product_component]
      return if save_and_redirect(@product_component, :url=>{:action=>:product, :id=>@product_component.product_id})
    end
    t3e :product=>@product.name, :component=>@product_component.name
    render_form
  end

  def product_component_delete
    return unless @product_component = find_and_check(:product_component)
    if request.post? or request.delete?
      @product_component.update_attributes!(:active=>false)
    end
    redirect_to :action=>:product, :id=>session[:product_id]
  end


  def self.products_conditions(options={})
    code = ""
    code += "conditions = [ \" company_id = ? AND (LOWER(code) LIKE ?  OR LOWER(name) LIKE ?) AND active = ? \" , @current_company.id, '%'+session[:product_key].to_s.lower+'%', '%'+session[:product_key].to_s.lower+'%', session[:product_active]] \n"
    code += "if session[:product_category_id].to_i != 0 \n"
    code += "conditions[0] += \" AND category_id = ?\" \n" 
    code += "conditions << session[:product_category_id].to_i \n"
    code += "end \n"
    code += "conditions \n"
    code
  end

  create_kame(:products, :conditions=>products_conditions) do |t|
    # t.column :number
    t.column :name, :through=>:category, :url=>{:action=>:product_category}
    t.column :name, :url=>{:action=>:product}
    t.column :code, :url=>{:action=>:product}
    t.column :manage_stocks
    t.column :nature_label
    t.column :label, :through=>:unit
    t.action :product_update
    t.action :product_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end
    
  def products
    #     @warehouses = Warehouse.find_all_by_company_id(@current_company.id)
    #     if @warehouses.size < 1
    #       notify(:need_stocks_warehouse_to_create_products, :warning)
    #       redirect_to :action=>:warehouse_create
    #     end
    @key = params[:key]||session[:product_key]||""
    session[:product_key] = @key
    session[:product_active] = true if session[:product_active].nil?
    if request.post?
      session[:product_active] = params[:product_active].nil? ? false : true
      session[:product_category_id] = params[:product].nil? ? 0 : params[:product][:category_id].to_i
    end
  end


  # create_kame(:stocks, :model=>:stocks, :conditions=>['company_id = ? AND virtual_quantity <= critic_quantity_min  AND product_id = ?', ['@current_company.id'], ['session[:product_id]']] , :line_class=>'RECORD.state') do |t|
  create_kame(:product_stocks, :model=>:stocks, :conditions=>['company_id = ? AND product_id = ?', ['@current_company.id'], ['session[:product_id]']] , :line_class=>'RECORD.state', :order=>"updated_at DESC") do |t|
    t.column :name, :through=>:warehouse, :url=>{:action=>:warehouse}
    t.column :name, :through=>:tracking, :url=>{:action=>:tracking}
    #t.column :quantity_max
    #t.column :quantity_min
    #t.column :critic_quantity_min
    t.column :virtual_quantity
    t.column :quantity
  end
  
  create_kame(:product_stock_moves, :model=>:stock_moves, :conditions=>{:company_id=>['@current_company.id'], :product_id =>['session[:product_id]']}, :line_class=>'RECORD.state', :order=>"updated_at DESC") do |t|
    t.column :name
    # t.column :name, :through=>:origin
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :name, :through=>:product, :url=>{:action=>:product}
    t.column :virtual
    t.column :created_at
  end
  
  def product
    return unless @product = find_and_check(:product)
    session[:product_id] = @product.id
    t3e @product.attributes
  end

  def change_quantities
    @stock = Stock.find(:first, :conditions=>{:warehouse_id=>params[:warehouse_id], :company_id=>@current_company.id, :product_id=>session[:product_id]} ) 
    if @stock.nil?
      @stock = Stock.new(:quantity_min=>1, :quantity_max=>0, :critic_quantity_min=>0)
    end
  end

  def product_create
    @warehouses = Warehouse.find_all_by_company_id(@current_company.id)
    if request.post?
      #raise Exception.new params.inspect
      @product = @current_company.products.new(params[:product])
      @product.duration = params[:product][:duration]
      @stock = @current_company.stocks.new(params[:stock])
      # @price = @current_company.prices.new(params[:price])
      ActiveRecord::Base.transaction do
        saved = @product.save
        if @product.manage_stocks and saved
          @stock.product_id = @product.id
          saved = false unless @stock.save
          @product.errors.add_from_record(@stock)
        end
#         if @product.to_sale and saved
#           @price.product_id = @product.id
#           @price.entity_id = @current_company.id
#           saved = false unless @price.save
#           @product.errors.add_from_record(@price)          
#         end
        raise ActiveRecord::Rollback unless saved
        return if save_and_redirect(@product, :saved=>saved)
      end
    else 
      @product = Product.new(:nature=>Product.natures.first[1])
      @stock = Stock.new
#      @price = Price.new
    end
    render_form
  end
  
  def product_update
    return unless @product = find_and_check(:product)
    session[:product_id] = @product.id
    @warehouses = Warehouse.find_all_by_company_id(@current_company.id)
    if !@product.manage_stocks
      @stock = Stock.new
    else
      @stock = Stock.find(:first, :conditions=>{:company_id=>@current_company.id ,:product_id=>@product.id} )||Stock.new 
    end
    if request.post?
      saved = false
      ActiveRecord::Base.transaction do
        if saved = @product.update_attributes(params[:product])
          if @stock.id.nil? and params[:product][:manage_stocks] == "1"
            @stock = Stock.new(params[:stock])
            @stock.product_id = @product.id
            @stock.company_id = @current_company.id 
            save = false unless @stock.save
            #raise Exception.new "ghghgh"
          elsif !@stock.id.nil? and @warehouses.size > 1
            save = false unless @stock.add_or_update(params[:stock],@product.id)
          else
            #save = false unless @stock.update_attributes(params[:stock])
            save = true
          end
          @product.errors.add_from_record(@stock)
        end
        raise ActiveRecord::Rollback unless saved  
      end
      return if save_and_redirect(@product, :saved=>saved)
    end
    t3e @product.attributes
    render_form
  end
  
  def product_delete
    return unless @product = find_and_check(:product)
    if request.post? or request.delete?
      @product.destroy
    end
    redirect_to_current
  end

  create_kame(:purchase_orders, :conditions=>search_conditions(:purchase_order, :purchase_orders=>[:created_on, :amount, :amount_with_taxes, :number, :reference_number, :comment], :entities=>[:code, :full_name]), :joins=>"JOIN #{Entity.table_name} AS entities ON (entities.id=supplier_id)", :line_class=>'RECORD.status', :order=>"created_on DESC, number DESC") do |t|
    t.column :number, :url=>{:action=>:purchase_order}
    t.column :reference_number, :url=>{:action=>:purchase_order}
    t.column :planned_on
    t.column :moved_on
    t.column :full_name, :through=>:supplier, :url=>{:controller=>:relations, :action=>:entity}
    # t.column :address, :through=>:dest_contact
    t.column :comment
    t.column :shipped
    # t.column :invoiced
    t.column :amount
    t.column :amount_with_taxes
    t.action :print, :url=>{:controller=>:company, :p0=>"RECORD.id", :id=>:purchase_order}
    t.action :purchase_order_update
    t.action :purchase_order_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.destroyable\?"
  end


  def purchase_orders
    session[:purchase_order_key] = params[:key] = params[:key] || session[:purchase_order_key] || ""
  end

  def purchase_order
    return unless @purchase_order = find_and_check(:purchase_order)
    session[:current_purchase_order_id] = @purchase_order.id
    t3e @purchase_order.attributes, :supplier=>@purchase_order.supplier.full_name
  end

  dyli(:entities, [:code, :full_name], :conditions => {:company_id=>['@current_company.id']})
  dyli(:suppliers, [:code, :full_name],  :model=>:entities, :conditions => {:company_id=>['@current_company.id'], :supplier=>true}, :order=>"active DESC, last_name, first_name")
  dyli(:purchase_products, [:code, :name],  :model=>:products, :conditions => {:company_id=>['@current_company.id'], :active=>true}, :order=>"name")
  #dyli(:contacts, [:address], :conditions => { :company_id=>['@current_company.id'], :entity_id=>['@current_company.entity_id']})

  manage :purchase_orders, :supplier_id=>"@current_company.entities.find(params[:supplier_id]).id rescue nil", :planned_on=>"Date.today", :redirect_to=>'{:action=>:purchase_order, :step=>:products, :id=>"id"}'

  create_kame(:purchase_order_lines, :conditions=>{:company_id=>['@current_company.id'], :order_id=>['session[:current_purchase_order_id]']}) do |t|
    t.column :name, :through=>:product, :url=>{:action=>:product}
    t.column :annotation
    t.column :tracking_serial
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :amount, :through=>:price
    t.column :amount
    t.column :amount_with_taxes
    t.action :purchase_order_line_update, :if=>'RECORD.order.moved_on.nil? '
    t.action :purchase_order_line_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>'RECORD.order.moved_on.nil? '
  end

  def purchase_order_lines
    return unless @purchase_order = find_and_check(:purchase_order)
    if params[:orientation]
      preference = @current_user.preference("interface.toggle.orientation", "vertical")
      preference.set params[:orientation]
      preference.save!
    end
    session[:current_purchase_order_id] = @purchase_order.id
    if request.post?
      @purchase_order.confirm
      redirect_to :action=>:purchase_order_summary, :id=>@purchase_order.id
    end
    t3e @purchase_order.attributes, :supplier=>@purchase_order.supplier.full_name
  end

  def price_find
    if !params[:purchase_order_line_price_id].blank?
      return unless @price = find_and_check(:price, params[:purchase_order_line_price_id])
      @product = @price.product if @price
    elsif params[:purchase_order_line_product_id]
      return unless @product = find_and_check(:product, params[:purchase_order_line_product_id])
      @price = @product.prices.find_by_active_and_by_default_and_entity_id(true, true, params[:entity_id]||@current_company.entity_id) if @product
    end
  end
  

  def purchase_order_line_create
    return unless @purchase_order = find_and_check(:purchase_order, params[:order_id])
    if @current_company.warehouses.size <= 0
      notify(:need_warehouse_to_create_purchase_order_line, :warning)
      redirect_to :action=>:warehouse_create
      return
    elsif @purchase_order.shipped
      notify(:impossible_to_add_lines_to_purchase, :warning)
      redirect_to :action=>:purchase_order, :step=>:products, :id=>@purchase_order.id
      return
    end
    if request.post?
      return unless product = find_and_check(:product, params[:purchase_order_line][:product_id].to_i)
      price = @current_company.prices.find(:first, :conditions=>{:product_id=>product.id, :entity_id=>@purchase_order.supplier_id, :amount=>params[:price][:amount].to_f, :tax_id=>params[:price][:tax_id].to_i})
      price = product.prices.create!(:entity_id=>@purchase_order.supplier_id, :amount=>params[:price][:amount], :tax_id=>params[:price][:tax_id].to_i, :active=>true) if price.nil?
      params[:purchase_order_line][:price_id] = price.id
      @purchase_order_line = @purchase_order.lines.new(params[:purchase_order_line])
      #         serial = params[:purchase_order_line][:tracking_serial].to_s.strip
      #         serial = nil if serial.blank?
      #         existing_purchase_order_line = @purchase_order.lines.find(:first, :conditions=>{:price_id=>price.id, :tracking_serial=>serial})
      #         if existing_purchase_order_line
      #           @purchase_order_line = existing_purchase_order_line
      #           @purchase_order_line.quantity += params[:purchase_order_line][:quantity].to_d
      #           @purchase_order_line.annotation = @purchase_order_line.annotation.to_s+params[:purchase_order_line][:annotation].to_s
      #         else
      #         end      
      return if save_and_redirect(@purchase_order_line, :url=>{:action=>:purchase_order, :step=>:products, :id=>@purchase_order.id})
    else
      @purchase_order_line = @purchase_order.lines.new
      @price = Price.new(:amount=>0.0)
    end
    t3e @purchase_order.attributes
    render_form
  end
  
  def purchase_order_line_update
    return unless @purchase_order_line = find_and_check(:purchase_order_line)
    if request.post?
      return unless product = find_and_check(:product, params[:purchase_order_line][:product_id].to_i)
      price = @current_company.prices.find(:first, :conditions=>{:product_id=>product.id, :entity_id=>@purchase_order_line.order.supplier_id, :amount=>params[:price][:amount].to_f, :tax_id=>params[:price][:tax_id].to_i})
      price = product.prices.create!(:entity_id=>@purchase_order_line.order.supplier_id, :amount=>params[:price][:amount], :tax_id=>params[:price][:tax_id].to_i, :active=>true) if price.nil?
      params[:purchase_order_line][:price_id] = price.id
      if @purchase_order_line.update_attributes(params[:purchase_order_line])  
        redirect_to :action=>:purchase_order, :step=>:products, :id=>@purchase_order_line.order_id  
      end
    end
    t3e @purchase_order_line.attributes
    render_form
  end
  
  def purchase_order_line_delete
    return unless @purchase_order_line = find_and_check(:purchase_order_line)
    if request.post? or request.delete?
      @purchase_order_line.destroy
    end
    redirect_to_current
  end


  #  create_kame(:purchase_order_deliveries, :model=>:incoming_deliveries)



  def purchase_order_deliveries
    return unless @purchase_order = find_and_check(:purchase_order)
  end



  create_kame(:purchase_order_payment_uses, :model=>:outgoing_payment_uses, :conditions=>{:company_id=>['@current_company.id'], :expense_id=>['session[:current_purchase_order_id]']}) do |t|
    t.column :number, :through=>:payment, :url=>{:action=>:outgoing_payment}
    t.column :amount, :through=>:payment, :label=>"payment_amount", :url=>{:action=>:outgoing_payment}
    t.column :amount
    t.column :payment_way
    t.column :downpayment
    t.column :to_bank_on, :through=>:payment, :label=>:column
    t.action :outgoing_payment_use_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete#, :if=>'RECORD.expense.shipped == false'
  end
  
  def purchase_order_summary
    return unless @purchase_order = find_and_check(:purchase_order)
    session[:current_purchase_order_id] = @purchase_order.id
    t3e @purchase_order.attributes
  end


  # manage :outgoing_payment_uses, :expense_id=>"(@current_company.purchase_orders.find(params[:expense_id]).id rescue 0)"

  def outgoing_payment_use_create
    return unless expense = find_and_check(:purchase_order, params[:expense_id])
    @outgoing_payment_use = OutgoingPaymentUse.new(:expense=>expense)
    if request.post?
      unless outgoing_payment = @current_company.outgoing_payments.find_by_id(params[:outgoing_payment_use][:payment_id])
        @outgoing_payment_use.errors.add(:payment_id, :required)
        return
      end
      if outgoing_payment.pay(expense, :downpayment=>params[:outgoing_payment_use][:downpayment])
        redirect_to_back
      end
    end
    t3e :number=>expense.number
    render_form
  end

  def outgoing_payment_use_delete
    return unless @outgoing_payment_use = find_and_check(:outgoing_payment_use)
    if request.post? or request.delete?
      redirect_to_current if @outgoing_payment_use.destroy #:action=>:purchase_order_summary, :id=>@purchase_order.id
    end
  end
  

  def self.outgoing_payments_conditions(options={})
    code = search_conditions(:outgoing_payments, :outgoing_payments=>[:amount, :parts_amount, :check_number, :number], :entities=>[:code, :full_name])+"||=[]\n"
    code += "if session[:outgoing_payment_state] == 'undelivered'\n"
    code += "  c[0] += ' AND delivered=?'\n"
    code += "  c << false\n"
    code += "elsif session[:outgoing_payment_state] == 'waiting'\n"
    code += "  c[0] += ' AND to_bank_on > ?'\n"
    code += "  c << Date.today\n"
    code += "elsif session[:outgoing_payment_state] == 'unparted'\n"
    code += "  c[0] += ' AND parts_amount != amount'\n"
    code += "end\n"
    code += "c\n"
    return code
  end

  create_kame(:outgoing_payments, :conditions=>outgoing_payments_conditions, :joins=>"LEFT JOIN #{Entity.table_name} AS entities ON entities.id = payee_id", :order=>"to_bank_on DESC", :line_class=>"(RECORD.parts_amount.zero? ? 'critic' : RECORD.unused_amount>0 ? 'warning' : '')") do |t|
    t.column :number, :url=>{:action=>:outgoing_payment}
    t.column :full_name, :through=>:payee, :url=>{:action=>:entity, :controller=>:relations}
    t.column :paid_on
    t.column :amount, :url=>{:action=>:outgoing_payment}
    t.column :parts_amount
    t.column :name, :through=>:mode
    t.column :check_number
    t.column :to_bank_on
    # t.column :label, :through=>:responsible
    t.action :outgoing_payment_update, :if=>"RECORD.updatable\?"
    t.action :outgoing_payment_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.destroyable\?"
  end

  def outgoing_payments
    session[:outgoing_payment_state] = params[:state]||session[:outgoing_payment_state]||"all"
    session[:outgoing_payment_key]   = params[:key]||session[:outgoing_payment_key]||""    
  end

  manage :outgoing_payments, :to_bank_on=>"Date.today", :paid_on=>"Date.today", :responsible_id=>"@current_user.id", :payee_id=>"(@current_company.entities.find(params[:payee_id]).id rescue 0)", :amount=>"params[:amount].to_f"


  create_kame(:outgoing_payment_purchase_orders, :model=>:purchase_orders, :conditions=>["purchase_orders.company_id=? AND id IN (SELECT expense_id FROM #{OutgoingPaymentUse.table_name} WHERE payment_id=?)", ['@current_company.id'], ['session[:current_outgoing_payment_id]']]) do |t|
    t.column :number, :url=>{:action=>:purchase_order}
    t.column :description, :through=>:supplier, :url=>{:action=>:entity, :controller=>:relations}
    t.column :created_on
    t.column :amount
    t.column :amount_with_taxes
  end
  
  def outgoing_payment
    return unless @outgoing_payment = find_and_check(:outgoing_payment)
    session[:current_outgoing_payment_id] = @outgoing_payment.id
    t3e :number=>@outgoing_payment.number, :payee=>@outgoing_payment.payee.full_name
  end



  def self.sales_orders_conditions
    code = ""
    code = search_conditions(:sales_order, :sales_orders=>[:amount, :amount_with_taxes, :number], :entities=>[:code, :full_name])+"||=[]\n"
    code += "unless session[:sales_order_state].blank? \n "
    code += "  if session[:sales_order_state] == 'current' \n "
    code += "    c[0] += \" AND state != 'C' \" \n " 
    code += "  elsif session[:sales_order_state] == 'unpaid' \n "
    code += "    c[0] += \"AND state NOT IN('C','E') AND parts_amount < amount_with_taxes\" \n "
    code += "  end\n "
    code += "end\n "
    code += "c\n "
    code
  end

  create_kame(:sales_orders, :conditions=>sales_orders_conditions, :joins=>"JOIN #{Entity.table_name} AS entities ON entities.id = #{SalesOrder.table_name}.client_id", :order=>'created_on desc', :line_class=>'RECORD.status' ) do |t|
    t.column :number, :url=>{:action=>:sales_order, :step=>:products}
    #t.column :name, :through=>:nature#, :url=>{:action=>:sales_order_nature}
    t.column :created_on
    t.column :full_name, :through=>:client, :url=>{:controller=>:relations, :action=>:entity}
    t.column :code, :through=>:client, :url=>{:controller=>:relations, :action=>:entity}, :label=>"client_code"
    t.column :state_label
    t.column :amount
    t.column :amount_with_taxes
    t.action :print, :url=>{:controller=>:company, :p0=>"RECORD.id", :id=>:sales_order}
    t.action :sales_order_delete, :method=>:delete, :if=>'RECORD.estimate? ', :confirm=>:are_you_sure_you_want_to_delete
  end
  
  def sales_order_delete
    return unless @sales_order = find_and_check(:sales_order)
    if request.post? or request.delete?
      if @sales_order.estimate?
        @sales_order.destroy
      else
        notify(:sales_order_cant_be_deleted, :error)
      end
    end
    redirect_to_current
  end
  
  def unpaid_sales_orders_export
    sales_orders = @current_company.sales_orders.find(:all, :conditions=>["state NOT IN('C','E') AND parts_amount < amount_with_taxes"], :order=>"created_on desc")
    csv_string = FasterCSV.generate do |csv|
      csv << [tc(:sales_invoice_number), tc(:unpaid_days),  tc(:unpaid_amount), tc(:code), tc(:full_name),tc(:address), tc(:client_phone), tc(:mobile), tc(:email), tc(:number), tc(:created_on), tc(:amount), tc(:amount_with_taxes), tc(:parts_amount), tc(:last_payment_date), tc(:last_payment_amount) , tc(:sales_order_products)]

      sales_orders.each do |sales_order|
        contact = sales_order.client.default_contact
        line = []
        line << [sales_order.sales_invoices.first ? "'"+sales_order.sales_invoices.first.number : "", sales_order.unpaid_days,sales_order.unpaid_amount(false,false), sales_order.client.code, sales_order.client.full_name]
        if contact
          line << [contact.address, "'"+contact.phone, "'"+contact.mobile, contact.email]
        else
          line << ["","","",""]
        end
        line << [sales_order.number, sales_order.created_on, sales_order.amount, sales_order.amount_with_taxes, sales_order.parts_amount, sales_order.last_payment ? sales_order.last_payment.created_on : "", sales_order.last_payment ? sales_order.last_payment.amount : "", sales_order.products]
        csv << line.flatten
      end
      
    end
    send_data csv_string, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment", :filename=>tc(:unpaid_sales_orders)+'.csv'
  end
  
  def sales_orders
    #raise Exception.new session[:sales_order_state].inspect
    session[:sales_order_state] ||= "all"
    @key = params[:key]||session[:sales_order_key]||""
    if request.post?
      #raise Exception.new params.inspect
      session[:sales_order_state] = params[:sales_order][:state]
      session[:sales_order_key] = @key
    end
  end
  

  create_kame(:sales_order_deliveries, :model=>:outgoing_deliveries, :children=>:lines, :conditions=>{:company_id=>['@current_company.id'], :sales_order_id=>['session[:current_sales_order_id]']}) do |t|
    t.column :address, :through=>:contact, :children=>:product_name
    t.column :planned_on, :children=>false
    t.column :moved_on, :children=>false
    # t.column :number, :through=>:sales_invoice, :url=>{:action=>:sales_invoice}, :children=>false
    t.column :quantity
    t.column :amount
    t.column :amount_with_taxes
    # t.action :outgoing_delivery_update, :if=>'RECORD.sales_invoice_id.nil? and RECORD.moved_on.nil? '
    t.action :outgoing_delivery_update, :if=>'!RECORD.sales_order.invoiced'
    # t.action :outgoing_delivery_delete, :if=>'RECORD.sales_invoice_id.nil? and RECORD.moved_on.nil? ', :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
    t.action :outgoing_delivery_delete, :if=>'!RECORD.sales_order.invoiced', :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end


  create_kame(:sales_order_invoices, :model=>:sales_invoices, :conditions=>{:company_id=>['@current_company.id'], :sales_order_id=>['session[:current_sales_order_id]']}, :children=>:lines) do |t|
    t.column :number, :children=>:designation, :url=>{:action=>:sales_invoice}
    # t.column :address, :through=>:contact, :children=>:product_name
    t.column :full_name, :through=>:client, :children=>false, :url=>{:controller=>:relations, :action=>:entity}
    t.column :created_on, :children=>false
    t.column :amount
    t.column :amount_with_taxes
    t.action :print, :url=>{:controller=>:company, :p0=>"RECORD.id", :id=>:sales_invoice}
  end
    
  
  create_kame(:sales_order_payments, :model=>:incoming_payments, :conditions=>["#{IncomingPayment.table_name}.company_id=? AND incoming_payment_uses.expense_id=? AND incoming_payment_uses.expense_type=?", ['@current_company.id'], ['session[:current_sales_order_id]'], SalesOrder.name], :joins=>"JOIN #{IncomingPaymentUse.table_name} AS incoming_payment_uses ON (#{IncomingPayment.table_name}.id=payment_id)") do |t|
   # t.column :id, :url=>{:action=>:incoming_payment}
    t.column :number, :url=>{:action=>:incoming_payment}
    t.column :full_name, :through=>:payer, :url=>{:controller=>:relations, :action=>:entity}
    #t.column :payment_way
    t.column :paid_on
    t.column :amount
  end
  
  def sales_order
    return unless @sales_order = find_and_check(:sales_order)
    session[:current_sales_order_id] = @sales_order.id
    if params[:step] == "deliveries"
      if @sales_order.deliveries.size <= 0 and not @sales_order.invoiced
        redirect_to :action=>:outgoing_delivery_create, :sales_order_id=>@sales_order.id
      elsif @sales_order.deliveries.size <= 0 and @sales_order.invoiced
        notify(:sales_order_already_invoiced)
      elsif @sales_order.lines.size <= 0
        notify(:no_lines_found, :warning)
        redirect_to :action=>:sales_order, :step=>:products, :id=>@sales_order.id
      end
    end

    t3e @sales_order.attributes, :client=>@sales_order.client.full_name, :state=>@sales_order.state_label
  end
  

  def sales_order_contacts
    return unless client = find_and_check(:entity)
    if request.xhr?
      session[:current_entity_id] = client.id
      cid = client.default_contact.id
      @sales_order = @current_company.sales_orders.find_by_id(params[:sales_order_id])||SalesOrder.new(:contact_id=>cid, :delivery_contact_id=>cid, :invoice_contact_id=>cid)
      render :partial=>'sales_order_contacts_form', :locals=>{:client=>client}
    end

#     if @sales_order
#       client_id = @sales_order.client_id
#     else
#       client_id = params[:client_id]||(params[:sales_order]||{})[:client_id]||session[:current_entity_id]
#       client_id = 0 if client_id.blank?
#     end
#     client = @current_company.entities.find_by_id(client_id)
#     session[:current_entity_id] = client_id
#     @contacts = (client ? client.contacts.collect{|x| [x.address, x.id]} : [])
#     render :text=>options_for_select(@contacts) if request.xhr?
  end

  dyli(:clients, [:code, :full_name], :model=>:entities, :conditions => {:company_id=>['@current_company.id'], :client=>true})
  dyli(:client_contacts, [:address] ,:model=>:contacts, :conditions=>["company_id = ? AND entity_id = ? AND deleted_at IS NULL", ['@current_company.id'], ['session[:current_entity_id]']])

  def sales_order_create
    if request.post?
      @sales_order = SalesOrder.new(params[:sales_order])
      @sales_order.company_id = @current_company.id
      @sales_order.number = ''
      if @sales_order.save
        redirect_to :action=>:sales_order, :step=>:products, :id=>@sales_order.id
      end
    else
      @sales_order = SalesOrder.new
      if client = @current_company.entities.find_by_id(params[:client_id]||params[:entity_id]||session[:current_entity_id])
        cid = client.default_contact.id
        @sales_order.attributes = {:contact_id=>cid, :delivery_contact_id=>cid, :invoice_contact_id=>cid}
      end
      session[:current_entity_id] = (client ? client.id : nil)
      @sales_order.responsible_id = @current_user.id
      @sales_order.client_id = session[:current_entity_id]
      @sales_order.letter_format = false
      @sales_order.function_title = tg('letter_function_title')
      @sales_order.introduction = tg('letter_introduction')
      # @sales_order.conclusion = tg('letter_conclusion')
    end
    render_form
  end

  def sales_order_update
    return unless @sales_order = find_and_check(:sales_order)
    unless @sales_order.estimate?
      notify(:sales_order_cannot_be_updated, :error)
      redirect_to :action=>:sales_order, :step=>:products, :id=>@sales_order.id
      return
    end
    if request.post?
      if @sales_order.update_attributes(params[:sales_order])
        redirect_to :action=>:sales_order, :step=>:products, :id=>@sales_order.id
        return
      end
    end
    t3e @sales_order.attributes
    render_form
  end




  # create_kame(:sales_order_lines, :conditions=>{:company_id=>['@current_company.id'], :order_id=>['session[:current_sales_order_id]'], :reduction_origin_id=>nil}, :children=>:reductions) do |t|
  create_kame(:sales_order_lines, :conditions=>{:company_id=>['@current_company.id'], :order_id=>['session[:current_sales_order_id]']}, :order=>:id, :export=>false) do |t|
    #t.column :name, :through=>:product
    t.column :label
    t.column :annotation
    t.column :serial, :through=>:tracking, :url=>{:action=>:tracking}
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :amount, :through=>:price
    t.column :amount
    t.column :amount_with_taxes
    t.action :sales_order_line_update, :if=>'RECORD.order.estimate? and RECORD.reduction_origin_id.nil? '
    t.action :sales_order_line_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>'RECORD.order.estimate? and RECORD.reduction_origin_id.nil? '
  end

  create_kame(:sales_order_subscriptions, :conditions=>{:company_id=>['@current_company.id'], :sales_order_id=>['session[:current_sales_order_id]']}, :model=>:subscriptions) do |t|
    t.column :number
    t.column :name, :through=>:nature
    t.column :full_name, :through=>:entity, :url=>{:controller=>:relations, :action=>:entity}
    t.column :address, :through=>:contact
    t.column :start
    t.column :finish
    t.column :quantity
    t.action :subscription_update
    t.action :subscription_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  def sales_order_line_detail
    if request.xhr?
      return unless price = find_and_check(:price)
      @sales_order = @current_company.sales_orders.find_by_id(params[:order_id]) if params[:order_id]
      @sales_order_line = @current_company.sales_order_lines.new(:product=>price.product, :price=>price, :price_amount=>0.0, :quantity=>1.0, :unit_id=>price.product.unit_id)
      if @sales_order
        @sales_order_line.order = @sales_order
        @sales_order_line.reduction_percent = @sales_order.client.max_reduction_percent 
      end
      render :partial=>"sales_order_line_detail#{'_row' if params[:mode]=='row'}_form"
    end
  end

#   def sales_order_lines
#     return unless @sales_order = find_and_check(:sales_order)
#     session[:current_sales_order_id] = @sales_order.id
#     session[:current_entity_category_id] = @sales_order.client.category_id
#     if params[:orientation]
#       preference = @current_user.preference("interface.toggle.orientation", "vertical")
#       preference.set params[:orientation]
#       preference.save!
#     end
#     @entity = @sales_order.client
#     session[:current_product_id] = @product.id if @product
#     @sales_order_line = @sales_order.lines.new
#     t3e :client=>@entity.full_name, :sales_order=>@sales_order.number
#   end

  def sales_order_confirm
    return unless @sales_order = find_and_check(:sales_order)
    if request.post?
      @sales_order.confirm
    end
    redirect_to :action=>:sales_order, :step=>:deliveries, :id=>@sales_order.id
  end


  def sales_order_invoice 
    return unless @sales_order = find_and_check(:sales_order)
    if request.post?
      ActiveRecord::Base.transaction do
        raise ActiveRecord::Rollback unless @sales_order.invoice
        redirect_to :action=>:sales_order, :step=>:summary, :id=>@sales_order.id
        return
      end
    end
    redirect_to :action=>:sales_order, :step=>:products, :id=>@sales_order.id
  end

  def sales_order_duplicate
    return unless sales_order = find_and_check(:sales_order)
    if request.post?
      if copy = sales_order.duplicate(:responsible_id=>@current_user.id)
        redirect_to :action=>:sales_order, :step=>:products, :id=>copy.id
        return
      end
    end
    redirect_to_current
  end

  
#   def calculate_sales_price(exist)
#     if exist
#       @sales_order_line.quantity += params[:sales_order_line][:quantity].to_d
#       @sales_order_line.amount = @price.amount*@sales_order_line.quantity
#       @sales_order_line.amount_with_taxes = @price.amount_with_taxes*@sales_order_line.quantity
#     else
#       @sales_order_line.amount = @price.amount*params[:sales_order_line][:quantity].to_d
#       @sales_order_line.amount_with_taxes = @price.amount_with_taxes*params[:sales_order_line][:quantity].to_d 
#     end
#   end

#   def subscription_find
#     return unless price = find_and_check(:prices, params[:sales_order_line_price_id])
#     product = price.product
#     if product.nature == "subscrip"
#       @subscription = Subscription.new(:product_id=>product.id, :company_id=>@current_company.id).compute_period
#     end
#   end

#   def sales_order_line_stocks
#     return unless price = find_and_check(:prices, params[:sales_order_line_price_id])
#     @product = price.product
#   end

#   def sales_order_line_tracking
#     if params[:sales_order_line_price_id]
#       return unless price = find_and_check(:prices, params[:sales_order_line_price_id])
#     end
#     return unless @product = find_and_check(:products, price.nil? ? session[:current_product_id] : price.product_id)
#     session[:current_product_id] = @product.id
#     return unless @warehouse = find_and_check(:warehouses, params[:sales_order_line_warehouse_id]||session[:current_warehouse_id])
#     session[:current_warehouse_id] = @warehouse.id
#     @sales_order_line = SalesOrderLine.new
#   end

#   def sales_order_line_informations
#     #raise Exception.new "okkkkk"
#     if params[:sales_order_line_price_id]
#       return unless price = find_and_check(:prices, params[:sales_order_line_price_id]) 
#     end
#     # puts session[:current_product_id].inspect+"!!!!!!!!"+price.inspect
#     return unless @product = find_and_check(:products, price.nil? ? session[:current_product_id] : price.product_id)
#     session[:current_product_id] = @product.id
#     return unless @warehouse = find_and_check(:warehouses, params[:sales_order_line_warehouse_id]||session[:current_warehouse_id])
#     #puts "okkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk"+params[:sales_order_line_warehouse_id].inspect+session[:current_warehouse_id].inspect+@warehouse.inspect
#     session[:current_warehouse_id] = @warehouse.id
#     #puts "okkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk"
#   end

  def subscription_message
    return unless price = find_and_check(:prices, params[:sales_order_line_price_id])
    @product = price.product
  end

  dyli(:all_contacts, [:address], :model=>:contacts, :conditions => {:company_id=>['@current_company.id'], :active=>true})
  dyli(:available_prices, ["products.name", "prices.amount", "prices.amount_with_taxes"], :model=>:prices, :joins=>"JOIN #{Product.table_name} AS products ON (product_id=products.id)", :conditions=>["prices.company_id=? AND prices.active=? AND products.active=?", ['@current_company.id'], true, true], :order=>"products.name, prices.amount")
  
  def sales_order_line_create
    return unless @sales_order = find_and_check(:sales_order, params[:order_id]||session[:current_sales_order_id])
    @warehouses = @current_company.warehouses
    default_attributes = {:company_id=>@current_company.id, :price_amount=>0.0, :reduction_percent=>@sales_order.client.max_reduction_percent}
    @sales_order_line = @sales_order.lines.new(default_attributes)
    if @current_company.available_prices.size > 0
      # @subscription = Subscription.new(:product_id=>@current_company.available_prices.first.product.id, :company_id=>@current_company.id).compute_period
      @product = @current_company.available_prices.first.product
      @warehouse = @warehouses.first
      session[:current_product_id] = @product.id
      session[:current_warehouse_id] = @warehouse.id
    else
      # @subscription = Subscription.new()
    end
    if @warehouses.empty? 
      notify(:need_warehouse_to_create_sales_order_line, :warning)
      redirect_to :action=>:warehouse_create
      return
    elsif @sales_order.active?
      notify(:impossible_to_add_lines, :error)
      redirect_to :action=>:sales_order, :step=>:products, :id=>@sales_order.id
      return
    elsif request.post? 
      @sales_order_line = @sales_order.lines.build(default_attributes)
      @sales_order_line.attributes = params[:sales_order_line]
      @sales_order_line.warehouse_id = @warehouses[0].id if @warehouses.size == 1

      ActiveRecord::Base.transaction do
        if saved = @sales_order_line.save
          if @sales_order_line.subscription?
            @subscription = @sales_order_line.new_subscription(params[:subscription])
            saved = false unless @subscription.save
            @subscription.errors.add_from_record(@sales_order_line)
          end
          raise ActiveRecord::Rollback unless saved
        end
        return if save_and_redirect(@sales_order_line, :url=>{:action=>:sales_order, :step=>:products, :id=>@sales_order.id}, :saved=>saved) 
      end
    end
    render_form
  end
  

  def sales_order_line_update
    return unless @sales_order_line = find_and_check(:sales_order_line)
    @sales_order = @sales_order_line.order 
    @warehouses = @current_company.warehouses
    @product = @sales_order_line.product
    @subscription = @current_company.subscriptions.find(:first, :conditions=>{:sales_order_id=>@sales_order.id}) || Subscription.new
    #raise Exception.new @subscription.inspect
    if request.post?
      @sales_order_line.attributes = params[:sales_order_line]
      return if save_and_redirect(@sales_order_line)
    end
    t3e :product=>@sales_order_line.product.name
    render_form
  end

  def sales_order_line_delete
    return unless @sales_order_line = find_and_check(:sales_order_line)
    if request.post? or request.delete?
       @sales_order_line.destroy
    end
    redirect_to_current
  end

 
  create_kame(:undelivered_quantities, :model=>:sales_order_lines, :conditions=>{:company_id=>['@current_company.id'], :order_id=>['session[:current_sales_order_id]'], :reduction_origin_id=>nil}) do |t|
    t.column :name, :through=>:product
    t.column :amount, :through=>:price
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :amount
    t.column :amount_with_taxes
    t.column :undelivered_quantity
  end



#   def sales_order_deliveries
#     return unless @sales_order = find_and_check(:sales_order)
#     session[:current_sales_order_id] = @sales_order.id
#     if @sales_order.deliveries.size <= 0 and not @sales_order.invoiced
#       redirect_to :action=>:outgoing_delivery_create, :sales_order_id=>@sales_order.id
#     elsif @sales_order.deliveries.size <= 0 and @sales_order.invoiced
#       notify(:sales_order_already_invoiced)
#     elsif @sales_order.lines.size <= 0
#       notify(:no_lines_found, :warning)
#       redirect_to :action=>:sales_order, :step=>:products, :id=>@sales_order.id
#     else
#       @undelivered_amount = @sales_order.undelivered :amount_with_taxes
#     end
#   end

  
  def sum_calculate
    return unless @sales_order = find_and_check(:sales_orders,session[:current_sales_order_id])
    @sales_order_lines = @sales_order.lines
    @outgoing_delivery = OutgoingDelivery.new(params[:outgoing_delivery])
    @outgoing_delivery_lines = OutgoingDeliveryLine.find_all_by_company_id_and_outgoing_delivery_id(@current_company.id, session[:current_outgoing_delivery])
    for line in  @sales_order_lines
      if params[:outgoing_delivery_line][line.id.to_s]
        @outgoing_delivery.amount_with_taxes += (line.price.amount_with_taxes*(params[:outgoing_delivery_line][line.id.to_s][:quantity]).to_f)
        @outgoing_delivery.amount += (line.price.amount*(params[:outgoing_delivery_line][line.id.to_s][:quantity]).to_f)
      end
    end
    @outgoing_delivery.amount = @outgoing_delivery.amount.round(2)
    @outgoing_delivery.amount_with_taxes = @outgoing_delivery.amount_with_taxes.round(2)
  end
  
  dyli(:delivery_contacts, ['entities.full_name', :address], :conditions => { :company_id=>['@current_company.id'], :active=>true}, :joins=>"JOIN #{Entity.table_name} AS entities ON (entity_id=entities.id)", :model=>:contacts)
  
  
  def outgoing_delivery_create
    return unless @sales_order = find_and_check(:sales_orders, params[:sales_order_id]||params[:order_id]||session[:current_sales_order_id])
    @outgoing_delivery_form = "outgoing_delivery_form"
    if @sales_order.invoiced
      notify(:sales_order_already_invoiced, :warning)
      redirect_to_back
    end
    sales_order_lines = @sales_order.lines
    if sales_order_lines.empty?
      notify(:no_lines_found, :warning)
      redirect_to_back
    end
    @outgoing_delivery_lines =  sales_order_lines.find_all_by_reduction_origin_id(nil).collect{|x| OutgoingDeliveryLine.new(:order_line_id=>x.id, :quantity=>x.undelivered_quantity)}
    @outgoing_delivery = OutgoingDelivery.new(:amount=>@sales_order.undelivered("amount"), :amount_with_taxes=>@sales_order.undelivered("amount_with_taxes"), :planned_on=>Date.today, :transporter_id=>@sales_order.transporter_id, :contact_id=>@sales_order.delivery_contact_id||@sales_order.client.default_contact)
    session[:current_outgoing_delivery] = @outgoing_delivery.id
  
    if request.post?
      @outgoing_delivery = @sales_order.deliveries.new(params[:outgoing_delivery])
      
      ActiveRecord::Base.transaction do
        saved = @outgoing_delivery.save
        if saved
          for line in sales_order_lines.find_all_by_reduction_origin_id(nil)
            if params[:outgoing_delivery_line][line.id.to_s][:quantity].to_f > 0
              outgoing_delivery_line = @outgoing_delivery.lines.new(:order_line_id=>line.id, :quantity=>params[:outgoing_delivery_line][line.id.to_s][:quantity].to_f)
              saved = false unless outgoing_delivery_line.save
              @outgoing_delivery.errors.add_from_record(outgoing_delivery_line)
            end
          end
        end
        raise ActiveRecord::Rollback unless saved  
        redirect_to :action=>:sales_order, :step=>:deliveries, :id=>session[:current_sales_order_id] 
      end
    end
    render_form(:id=>@outgoing_delivery_form)
  end
  
  def outgoing_delivery_update
    return unless @outgoing_delivery = find_and_check(:outgoing_delivery)
    @outgoing_delivery_form = "outgoing_delivery_form"
    session[:current_outgoing_delivery] = @outgoing_delivery.id
    @sales_order = @outgoing_delivery.sales_order
    # return unless @sales_order = find_and_check(:sales_orders, session[:current_sales_order_id])
    # sales_order_lines = SalesOrderLine.find(:all,:conditions=>{:company_id=>@current_company.id, :order_id=>session[:current_sales_order_id]})
    # @outgoing_delivery_lines = OutgoingDeliveryLine.find(:all,:conditions=>{:company_id=>@current_company.id, :outgoing_delivery_id=>@outgoing_delivery.id})
    @outgoing_delivery_lines = @outgoing_delivery.lines
    if request.post?
      ActiveRecord::Base.transaction do
        saved = @outgoing_delivery.update_attributes!(params[:outgoing_delivery])
        if saved
          for line in @outgoing_delivery.lines
            saved = false unless line.update_attributes(:quantity=>params[:outgoing_delivery_line][line.order_line.id.to_s][:quantity])
            @outgoing_delivery.errors.add_from_record(line)
          end
        end
        raise ActiveRecord::Rollback unless saved
        redirect_to :action=>:sales_order, :step=>:deliveries, :id=>session[:current_sales_order_id] 
      end
    end
    render_form(:id=>@outgoing_delivery_form)
  end
 

  def outgoing_delivery_delete
    return unless @outgoing_delivery = find_and_check(:outgoing_delivery)
    if request.post? or request.delete?
      @outgoing_delivery.destroy
    end
    redirect_to_current
  end


  
  create_kame(:deposits, :conditions=>{:company_id=>['@current_company.id']}, :order=>"created_at DESC") do |t|
    t.column :number, :url=>{:action=>:deposit}
    t.column :amount, :url=>{:action=>:deposit}
    t.column :payments_count
    t.column :name, :through=>:cash, :url=>{:action=>:cash, :controller=>:accountancy}
    t.column :label, :through=>:responsible
    t.column :created_on
    t.action :print, :url=>{:controller=>:company, :p0=>"RECORD.id", :id=>:deposit}
    t.action :deposit_update, :if=>'RECORD.locked == false'
    t.action :deposit_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>'RECORD.locked == false'
  end

#  dyli(:cash, :attributes => [:name], :conditions => {:company_id=>['@current_company.id'], :entity_id=>['@current_company.entity_id']})

  create_kame(:deposit_payments, :model=>:incoming_payments, :conditions=>{:company_id=>['@current_company.id'], :deposit_id=>['session[:deposit_id]']}, :per_page=>1000, :order=>:number) do |t|
    t.column :number, :url=>{:action=>:incoming_payment}
    t.column :full_name, :through=>:payer, :url=>{:controller=>:relations, :action=>:entity}
    t.column :bank
    t.column :account_number
    t.column :check_number
    t.column :paid_on
    t.column :amount, :url=>{:action=>:incoming_payment}
  end

  create_kame(:depositable_payments, :model=>:incoming_payments, :conditions=>["company_id=? AND (deposit_id=? OR (mode_id=? AND deposit_id IS NULL))", ['@current_company.id'], ['session[:deposit_id]'], ['session[:payment_mode_id]']], :pagination=>:none, :order=>"to_bank_on, created_at", :line_class=>"((RECORD.to_bank_on||Date.yesterday)>Date.today ? 'critic' : '')") do |t|
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
  


  create_kame(:sales_order_payment_uses, :model=>:incoming_payment_uses, :conditions=>["company_id=? AND expense_id=? AND expense_type=?", ['@current_company.id'], ['session[:current_sales_order_id]'], SalesOrder.name]) do |t|
    t.column :number, :through=>:payment, :url=>{:action=>:incoming_payment}
    t.column :amount, :through=>:payment, :label=>"payment_amount", :url=>{:action=>:incoming_payment}
    t.column :amount
    t.column :payment_way
    t.column :scheduled, :through=>:payment, :datatype=>:boolean, :label=>:column
    t.column :downpayment
    # t.column :paid_on, :through=>:payment, :label=>:column, :datatype=>:date
    t.column :to_bank_on, :through=>:payment, :label=>:column, :datatype=>:date
    t.action :incoming_payment_use_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  
#   def sales_order_summary
#     return unless @sales_order = find_and_check(:sales_orders, params[:id]||session[:current_sales_order_id])
#     session[:current_sales_order_id] = @sales_order.id
#     t3e @sales_order.attributes
#   end



  def self.incoming_payments_conditions(options={})
    code = search_conditions(:incoming_payments, :incoming_payments=>[:amount, :parts_amount, :check_number, :number], :entities=>[:code, :full_name])+"||=[]\n"
    code += "if session[:incoming_payment_state] == 'unreceived'\n"
    code += "  c[0] += ' AND received=?'\n"
    code += "  c << false\n"
    code += "elsif session[:incoming_payment_state] == 'waiting'\n"
    code += "  c[0] += ' AND to_bank_on > ?'\n"
    code += "  c << Date.today\n"
    code += "elsif session[:incoming_payment_state] == 'undeposited'\n"
    code += "  c[0] += ' AND deposit_id IS NULL'\n"
    code += "elsif session[:incoming_payment_state] == 'unparted'\n"
    code += "  c[0] += ' AND parts_amount != amount'\n"
    code += "end\n"
    code += "c\n"
    return code
  end
 
  create_kame(:incoming_payments, :conditions=>incoming_payments_conditions, :joins=>"LEFT JOIN #{Entity.table_name} AS entities ON entities.id = #{IncomingPayment.table_name}.payer_id", :order=>"to_bank_on DESC") do |t|
    t.column :number, :url=>{:action=>:incoming_payment}
    t.column :full_name, :through=>:payer, :url=>{:controller=>:relations, :action=>:entity}
    t.column :paid_on
    t.column :amount, :url=>{:action=>:incoming_payment}
    t.column :parts_amount
    t.column :name, :through=>:mode
    t.column :check_number
    t.column :to_bank_on
    # t.column :label, :through=>:responsible
    t.column :number, :through=>:deposit, :url=>{:action=>:deposit}
    t.action :incoming_payment_update, :if=>"RECORD.deposit.nil\?"
    t.action :incoming_payment_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.parts_amount.to_f<=0"
  end

  def incoming_payments
    session[:incoming_payment_state] = params[:state]||session[:incoming_payment_state]||"all"
    session[:incoming_payment_key]   = params[:key]||session[:incoming_payment_key]||""
  end
  manage :incoming_payments, :to_bank_on=>"Date.today", :paid_on=>"Date.today", :responsible_id=>"@current_user.id", :payer_id=>"(@current_company.entities.find(params[:payer_id]).id rescue 0)", :amount=>"params[:amount].to_f", :bank=>"params[:bank]", :account_number=>"params[:account_number]"

  create_kame(:incoming_payment_sales_orders, :model=>:sales_orders, :conditions=>["#{SalesOrder.table_name}.company_id=? AND id IN (SELECT expense_id FROM #{IncomingPaymentUse.table_name} WHERE payment_id=? AND expense_type=?)", ['@current_company.id'], ['session[:current_payment_id]'], SalesOrder.name]) do |t|
    t.column :number, :url=>{:action=>:sales_order}
    t.column :description, :through=>:client, :url=>{:action=>:entity, :controller=>:relations}
    t.column :created_on
    t.column :amount
    t.column :amount_with_taxes
  end
  
  def incoming_payment
    return unless @incoming_payment = find_and_check(:incoming_payment)
    session[:current_payment_id] = @incoming_payment.id
    t3e :number=>@incoming_payment.number, :entity=>@incoming_payment.payer.full_name
  end


  
  
  def incoming_payment_use_create
    unless expense_type = (params[:expense_type]||session[:expense_type])
      redirect_to_back
      return
    end
    return unless expense = find_and_check(expense_type, params[:expense_id]||session[:expense_id])
    @incoming_payment_use = IncomingPaymentUse.new(:expense=>expense)
    if request.post?
      unless incoming_payment = @current_company.incoming_payments.find_by_id(params[:incoming_payment_use][:payment_id])
        @incoming_payment_use.errors.add(:payment_id, :required)
        return
      end
      if incoming_payment.pay(expense, :downpayment=>params[:incoming_payment_use][:downpayment])
        redirect_to_back
      end
    end
    t3e :type=>t("activerecord.models."+expense_type), :number=>expense.number
    render_form
  end

  def incoming_payment_use_delete
    # return unless @sales_order   = find_and_check(:sales_order, session[:current_sales_order_id])
    return unless @incoming_payment_use = find_and_check(:incoming_payment_use)
    if request.post? or request.delete?
      redirect_to_current if @incoming_payment_use.destroy #:action=>:sales_order, :step=>:summary, :id=>@sales_order.id
    end
  end
  

  create_kame(:product_categories, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :comment
    t.column :catalog_name
    t.column :catalog_description
    t.column :name, :through=>:parent
    t.action :product_category_update
    t.action :product_category_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  def product_categories
   # shelves_list params
  end

  create_kame(:product_category_products, :model=>:products, :conditions=>{:company_id=>['@current_company.id'], :category_id=>['session[:current_product_category_id]']}, :order=>'active DESC, name') do |t|
    t.column :number
    t.column :name, :url=>{:action=>:product}
    t.column :code, :url=>{:action=>:product}
    t.column :description
    t.column :active
    t.action :product_update
    t.action :product_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  def product_category
    return unless @product_category = find_and_check(:product_category)
    session[:current_product_category_id] = @product_category.id
    t3e @product_category.attributes
  end

  manage :product_categories

  create_kame(:sales_order_natures, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :active
    t.column :name, :through=>:expiration, :url=>{:action=>:delay}
    t.column :name, :through=>:payment_delay, :url=>{:action=>:delay}
    t.column :downpayment
    t.column :downpayment_minimum
    t.column :downpayment_rate
    t.column :comment
    t.action :sales_order_nature_update
    t.action :sales_order_nature_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end
  def sales_order_natures
  end
  manage :sales_order_natures
  

  create_kame(:outgoing_delivery_modes, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :code
    t.column :comment
    t.action :outgoing_delivery_mode_update
    t.action :outgoing_delivery_mode_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end
  def outgoing_delivery_modes
  end
  manage :outgoing_delivery_modes

  dyli(:account, ["number:X%", :name], :conditions =>{:company_id=>['@current_company.id']})

  create_kame(:incoming_payment_modes, :conditions=>{:company_id=>['@current_company.id']}, :order=>:position) do |t|
    t.column :name
    t.column :with_accounting
    t.column :name, :through=>:cash, :url=>{:controller=>:accountancy, :action=>:cash}
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
  manage_list :incoming_payment_modes

  
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
    t.column :name, :through=>:cash, :url=>{:controller=>:accountancy, :action=>:cash}
    t.action :outgoing_payment_mode_up, :method=>:post, :if=>"!RECORD.first\?"
    t.action :outgoing_payment_mode_down, :method=>:post, :if=>"!RECORD.last\?"
    t.action :outgoing_payment_mode_update
    t.action :outgoing_payment_mode_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.destroyable\?"
  end
  def outgoing_payment_modes
  end
  manage :outgoing_payment_modes, :with_accounting=>"true"
  manage_list :outgoing_payment_modes



  create_kame(:warehouses, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name, :url=>{:action=>:warehouse}
    t.column :comment
    t.column :name, :through=>:establishment
    t.column :name, :through=>:parent, :url=>{:action=>:warehouse}
    t.column :reservoir
    #t.action :warehouse_update, :mode=>:reservoir, :if=>'RECORD.reservoir == true'
    t.action :warehouse_update
    t.action :warehouse_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  def warehouses
    unless @current_company.warehouses.size>0
      notify(:need_warehouse_to_record_stock_moves)
      redirect_to :action=>:warehouse_create
      return
    end
  end



  create_kame(:warehouse_stock_moves, :model=>:stock_moves, :conditions=>{:company_id=>['@current_company.id'], :warehouse_id=>['session[:current_warehouse_id]']}) do |t|
    t.column :name
    t.column :planned_on
    t.column :moved_on
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :name, :through=>:product, :url=>{:action=>:product}
    t.column :virtual
    t.action :stock_move_update, :if=>'RECORD.generated != true'
    t.action :stock_move_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete,:if=>'RECORD.generated != true' 
  end
  

  create_kame(:warehouse_stocks, :model=>:stocks, :conditions=>{:company_id=>['@current_company.id'], :warehouse_id=>['session[:current_warehouse_id]']}, :order=>"quantity DESC") do |t|
    t.column :name, :through=>:product,:url=>{:action=>:product}
    t.column :name, :through=>:tracking, :url=>{:action=>:tracking}
    t.column :weight, :through=>:product, :label=>:column
    t.column :quantity_max
    t.column :quantity_min
    t.column :critic_quantity_min
    t.column :virtual_quantity
    t.column :quantity
  end
  

  def warehouse
    return unless @warehouse = find_and_check(:warehouse)
    session[:current_warehouse_id] = @warehouse.id
    t3e @warehouse.attributes
  end

  manage :warehouses, :reservoir=>"params[:reservoir]"

  manage :stock_moves, :planned_on=>'Date.today'

  create_kame(:subscription_natures, :conditions=>{:company_id=>['@current_company.id']}, :children=>:products) do |t|
    t.column :name, :url=>{:id=>'nil', :action=>:subscriptions, :nature_id=>"RECORD.id"}
    t.column :nature_label, :children=>false
    t.column :actual_number, :children=>false
    t.column :reduction_rate, :children=>false
    t.action :subscription_nature_increment, :method=>:post, :if=>"RECORD.nature=='quantity'"
    t.action :subscription_nature_decrement, :method=>:post, :if=>"RECORD.nature=='quantity'"
    t.action :subscription_nature_update
    t.action :subscription_nature_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.destroyable\?"
  end

  def subscription_natures
  end

  manage :subscription_natures, :nature=>"SubscriptionNature.natures.first[1]"

  def subscription_nature
    return unless @subscription_nature = find_and_check(:subscription_nature)
    session[:subscription_nature] = @subscription_nature
    redirect_to :action=>:subscriptions, :nature_id=>@subscription_nature.id
  end

  def subscription_nature_increment
    return unless @subscription_nature = find_and_check(:subscription_nature)
    if request.post?
      @subscription_nature.increment!(:actual_number)
      notify(:new_actual_number, :success, :actual_number=>@subscription_nature.actual_number)
    end
    redirect_to_current
  end

  def subscription_nature_decrement
    return unless @subscription_nature = find_and_check(:subscription_nature)
    if request.post?
      @subscription_nature.decrement!(:actual_number)
      notify(:new_actual_number, :success, :actual_number=>@subscription_nature.actual_number)
    end
    redirect_to_current
  end

  def self.subscriptions_conditions(options={})
    code = ""
    code += "conditions = [ \" company_id = ? AND COALESCE(sales_order_id, 0) NOT IN (SELECT id FROM #{SalesOrder.table_name} WHERE company_id = ? and state = 'E') \" , @current_company.id, @current_company.id]\n"
    code += "if session[:subscriptions].is_a? Hash\n"
    code += "  if session[:subscriptions][:nature].is_a? Hash\n"
    code += "    conditions[0] += \" AND nature_id = ?\" \n "
    code += "    conditions << session[:subscriptions][:nature]['id'].to_i\n"
    code += "  end\n"
    code += "  if session[:subscriptions][:nature]['nature'] == 'quantity'\n"
    code += "    conditions[0] += \" AND ? BETWEEN first_number AND last_number\"\n"
    code += "  elsif session[:subscriptions][:nature]['nature'] == 'period'\n"
    code += "    conditions[0] += \" AND ? BETWEEN started_on AND stopped_on\"\n"
    code += "  end\n"
    code += "  conditions << session[:subscriptions][:instant]\n"
    code += "end\n"
    code += "conditions\n"
    code
  end

  create_kame(:subscriptions, :conditions=>subscriptions_conditions, :order=> "id DESC") do |t|
    t.column :full_name, :through=>:entity, :url=>{:action=>:entity, :controller=>:relations}
    t.column :line_2, :through=>:contact, :label=>:column
    t.column :line_3, :through=>:contact, :label=>:column
    t.column :line_4, :through=>:contact, :label=>:column
    t.column :line_5, :through=>:contact, :label=>:column
    t.column :line_6_code, :through=>:contact, :label=>:column
    t.column :line_6_city, :through=>:contact, :label=>:column
    t.column :name, :through=>:product
    t.column :quantity
    #t.column :started_on
    #t.column :finished_on
    #t.column :first_number
    #t.column :last_number
    t.column :start
    t.column :finish
  end

#   def subscription_options
#     return unless @subscription_nature = find_and_check(:subscription_nature, params[:nature])
#     #instant = (@subscription_nature.period? ? params[:instant].to_date : params[:instant]) rescue nil 
#     #session[:subscriptions][:instant] = instant||@subscription_nature.now
#     session[:subscriptions][:instant] = @subscription_nature.now
#     render :partial=>'subscription_options'
#   end


  def subscriptions
    if @current_company.subscription_natures.size == 0
      notify(:need_to_create_subscription_nature)
      redirect_to :action=>:subscription_natures
      return
    end

    if request.xhr?
      return unless @subscription_nature = find_and_check(:subscription_nature, params[:nature_id])
      session[:subscriptions][:instant] = @subscription_nature.now
      render :partial=>'subscriptions_options'
      return
    else
      if params[:nature_id]
        return unless @subscription_nature = find_and_check(:subscription_nature, params[:nature_id])
      end
      @subscription_nature ||= @current_company.subscription_natures.first
      instant = (@subscription_nature.period? ? params[:instant].to_date : params[:instant]) rescue nil 
      session[:subscriptions] ||= {}
      session[:subscriptions][:nature]  = @subscription_nature.attributes
      session[:subscriptions][:instant] = (instant.blank? ? @subscription_nature.now : instant)
    end
  end

  # dyli(:subscription_contacts,  [:address] ,:model=>:contact, :conditions=>{:entity_id=>['session[:current_entity_id]'], :active=>true, :company_id=>['@current_company.id']})
  dyli(:subscription_contacts,  ['entities.code', 'entities.full_name', :address] ,:model=>:contact, :joins=>"JOIN #{Entity.table_name} AS entities ON (entity_id=entities.id)", :conditions=>["entities.company_id=? AND deleted_at IS NULL", ['@current_company.id']])
  
  manage :subscriptions, :contact_id=>"@current_company.contacts.find_by_entity_id(params[:entity_id]).id rescue 0", :entity_id=>"@current_company.entities.find(params[:entity_id]).id rescue 0", :nature_id=>"@current_company.subscription_natures.first.id rescue 0", :t3e=>{:nature=>"@subscription.nature.name", :start=>"@subscription.start", :finish=>"@subscription.finish"}

#   def subscriptions_period
#     @subscription = Subscription.new(:nature=>@current_company.subscription_natures.find_by_id(params[:subscription_nature_id].to_i))
#     render :partial=>'subscriptions_period_form'
#   end
  
  def subscription_coordinates
    nature, attributes = nil, {}
    if params[:nature_id]
      return unless nature = find_and_check(:subscription_nature, params[:nature_id])
    elsif params[:price_id]
      return unless price = find_and_check(:price, params[:price_id])
      if price.product.subscription?
        nature = price.product.subscription_nature 
        attributes[:product_id] = price.product_id
      end
    end
    if nature
      attributes[:contact_id] = (@current_company.contacts.find_by_entity_id(params[:entity_id]).id rescue 0)
      @subscription = nature.subscriptions.new(attributes)
      @subscription.compute_period
    end
    mode = params[:mode]||:coordinates
    render :partial=>"subscription_#{mode}_form"
  end
  
  
  create_kame :undelivered_sales, :model=>:outgoing_deliveries, :children=>:lines, :conditions=>{:company_id=>['@current_company.id'], :moved_on=>nil}, :line_class=>'RECORD.moment.to_s' do |t|
    t.column :label, :children=>:product_name
    t.column :planned_on, :children=>false
    t.column :quantity, :datatype=>:decimal
    t.column :amount
    t.column :amount_with_taxes
    t.check_box :delivered, :value=>'RECORD.planned_on<=Date.today'
  end


  def undelivered_sales
    @deliveries = OutgoingDelivery.find(:all,:conditions=>{:company_id=>@current_company.id, :moved_on=>nil},:order=>"planned_on ASC")  
    if request.post?
      for id, values in params[:undelivered_sales]
        #raise Exception.new params.inspect+id.inspect+values.inspect
        outgoing_delivery = @current_company.deliveries.find_by_id(id)
        outgoing_delivery.ship if outgoing_delivery and values[:delivered].to_i == 1
      end
      redirect_to :action=>:undelivered_sales
    end
  end
  

  create_kame(:unexecuted_transfers, :model=>:stock_transfers, :conditions=>{:company_id=>['@current_company.id'], :moved_on=>nil}, :order=>"planned_on") do |t| 
    t.column :text_nature
    t.column :name, :through=>:product
    t.column :quantity, :datatype=>:decimal
    t.column :name, :through=>:warehouse
    t.column :name, :through=>:second_warehouse
    t.column :planned_on, :children=>false
    t.check_box :executed, :value=>'RECORD.planned_on<=Date.today'
  end
  
  def unexecuted_transfers
    @stock_transfers = @current_company.stock_transfers.find(:all, :conditions=>{:moved_on=>nil}, :order=>"planned_on ASC")
    if request.post?
      for id, values in params[:unexecuted_transfers]
        return unless transfer = find_and_check(:stock_transfer, id)
        transfer.execute_transfer if transfer and values[:executed].to_i == 1
      end
      redirect_to :action=>:unexecuted_transfers
    end
  end
  
#   create_kame(:unreceived_purchases, :model=>:purchase_orders, :children=>:lines, :conditions=>{:company_id=>['@current_company.id'], :moved_on=>nil}, :order=>"planned_on") do |t| 
#     t.column :label, :children=>:product_name
#     t.column :planned_on, :children=>false
#     t.column :quantity, :datatype=>:decimal
#     t.column :amount
#     t.column :amount_with_taxes
#     t.check_box :received, :value=>'RECORD.planned_on<=Date.today'
#    # t.action :validate_purchase
#   end

#   def unreceived_purchases
#     @purchase_orders = PurchaseOrder.find(:all, :conditions=>{:company_id=>@current_company.id, :moved_on=>nil}, :order=>"planned_on ASC")
#     if request.post?
#       for id, values in params[:unreceived_purchases]
#         return unless purchase = find_and_check(:purchase_order, id)
#         purchase.real_stocks_moves_create if purchase and values[:received].to_i == 1
#       end
#       redirect_to :action=>:unreceived_purchases
#     end
#   end

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
  
  def self.stocks_conditions(options={})
    code = ""
    code += "conditions = {} \n"
    code += "conditions[:company_id] = @current_company.id\n"
    code += "conditions[:warehouse_id] = session[:warehouse_id].to_i if session[:warehouse_id] and session[:warehouse_id].to_i > 0\n "
    code += "conditions \n "
    code
  end

  create_kame(:stocks, :conditions=>stocks_conditions, :line_class=>'RECORD.state') do |t|
    t.column :name, :through=>:warehouse,:url=>{:action=>:warehouse}
    t.column :name, :through=>:product,:url=>{:action=>:product}
    t.column :name, :through=>:tracking, :url=>{:action=>:tracking}
    t.column :weight, :through=>:product, :label=>:column
    t.column :quantity_max
    t.column :quantity_min
    t.column :critic_quantity_min
    t.column :virtual_quantity, :precision=>3
    t.column :quantity, :precision=>3
    t.column :label, :through=>:unit
  end

  create_kame(:critic_stocks, :model=>:stocks, :conditions=>['company_id = ? AND virtual_quantity <= critic_quantity_min', ['@current_company.id']] , :line_class=>'RECORD.state') do |t|
    t.column :name, :through=>:product,:url=>{:action=>:product}
    # t.column :name, :through=>:warehouse
    t.column :quantity_max
    t.column :quantity_min
    t.column :critic_quantity_min
    t.column :virtual_quantity
    t.column :quantity
  end

  def stocks
    @warehouses = @current_company.warehouses
    if @warehouses.size == 0
      notify(:no_warehouse, :warning)
      redirect_to :action=>:warehouse_create
    else
      session[:warehouse_id] = params[:warehouse_id]
    end
    notify(:no_stocks, :now) if @current_company.stocks.size <= 0
  end

  create_kame(:stock_transfers, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :text_nature
    t.column :name, :through=>:product, :url=>{:action=>:product}
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :name, :through=>:warehouse, :url=>{:action=>:warehouse}
    t.column :name, :through=>:second_warehouse, :url=>{:action=>:warehouse}
    t.column :planned_on
    t.column :moved_on
    t.action :stock_transfer_update
    t.action :stock_transfer_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  def stock_transfers
  end

  manage :stock_transfers, :nature=>"'transfer'", :planned_on=>"Date.today"

  create_kame(:transports, :children=>:deliveries, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :created_on, :children=>:planned_on, :url=>{:action=>:transport}
    t.column :transport_on, :children=>false, :url=>{:action=>:transport}
    t.column :full_name, :through=>:transporter, :children=>:contact_address, :url=>{:controller=>:relations, :action=>:entity}
    t.column :weight
    t.action :print, :url=>{:controller=>:company, :p0=>"RECORD.id", :id=>:transport}
    t.action :transport_update
    t.action :transport_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  create_kame(:transport_deliveries, :model=>:outgoing_deliveries, :children=>:lines, :conditions=>{:company_id=>['@current_company.id'], :transport_id=>['session[:current_transport]']}) do |t|
    t.column :address, :through=>:contact, :children=>:product_name
    t.column :planned_on, :children=>false
    t.column :moved_on, :children=>false
    t.column :number, :through=>:sales_invoice, :url=>{:action=>:sales_invoice}, :children=>false
    t.column :quantity
    t.column :amount
    t.column :amount_with_taxes
    t.column :weight, :children=>false
    t.action :transport_outgoing_delivery_delete, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete_outgoing_delivery
  end
  
  def transports
  end

  def transport
    return unless @transport = find_and_check(:transports)
    session[:current_transport] = @transport.id
    t3e @transport.attributes
  end
  
  # manage :transports, :transport_on=>'Date.today', :responsible_id=>'@current_user.id', :redirect_to=>'{:action=>:transport_deliveries, :id=>"id"}'

  def transport_create
    @transport = Transport.new(:transport_on=>Date.today, :responsible_id=>@current_user.id)
    @transport.responsible_id = @current_user.id
    session[:current_transport] = 0
    if request.post?
      @transport = Transport.new(params[:transport])
      @transport.company_id = @current_company.id
      @transport.save
      return if save_and_redirect(@transport, :url=>{:action=>:transport_deliveries, :id=>@transport.id})
    end
    render_form
  end

  def transport_update
    return unless @transport = find_and_check(:transports)
    session[:current_transport] = @transport.id
    if request.post?
      return if save_and_redirect(@transport, :url=>{:action=>:transport_deliveries, :id=>@transport.id}, :attributes=>params[:transport])
    end
  end
  
  def transport_delete
    #raise Exception.new params.inspect
    return unless @transport = find_and_check(:transports)
    if request.post? or request.delete?
      @transport.destroy
    end
    redirect_to :action=>:transports
  end

  dyli(:outgoing_deliveries, [:planned_on, "contacts.address"], :conditions=>["deliveries.company_id = ? AND transport_id IS NULL", ['@current_company.id']], :joins=>"INNER JOIN #{Contact.table_name} AS contacts ON contacts.id = deliveries.contact_id ")
  
  def transport_deliveries
    return unless @transport = find_and_check(:transports, params[:id]||session[:current_transport])
    session[:current_transport] = @transport.id
    if request.post?
      return unless outgoing_delivery = find_and_check(:outgoing_deliveries, params[:outgoing_delivery][:id].to_i)
      if outgoing_delivery
        redirect_to :action=>:transport_update, :id=>@transport.id if outgoing_delivery.update_attributes(:transport_id=>@transport.id) 
      end
    end
  end
  
  def transport_delivery_delete
    return unless @outgoing_delivery =  find_and_check(:outgoing_delivery)
    if request.post? or request.delete?
      @outgoing_delivery.update_attributes!(:transport_id=>nil)
    end
    redirect_to_current
  end


  create_kame(:tracking_stocks, :model=>:stocks, :conditions=>{:company_id => ['@current_company.id'], :tracking_id=>['session[:current_tracking_id]']}, :line_class=>'RECORD.state') do |t|
    t.column :weight, :through=>:product, :label=>:column
    t.column :quantity_max
    t.column :quantity_min
    t.column :critic_quantity_min
    t.column :virtual_quantity
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :name, :through=>:warehouse, :url=>{:action=>:warehouse}
  end

  create_kame(:tracking_purchase_order_lines, :model=>:purchase_order_lines, :conditions=>{:company_id => ['@current_company.id'], :tracking_id=>['session[:current_tracking_id]']}, :order=>'order_id') do |t|
    t.column :number, :through=>:order, :url=>{:action=>:purchase_order}    
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :name, :through=>:warehouse, :url=>{:action=>:warehouse}
  end

  create_kame(:tracking_operation_lines, :model=>:operation_lines, :conditions=>{:company_id => ['@current_company.id'], :tracking_id=>['session[:current_tracking_id]']}, :order=>'operation_id') do |t|
    t.column :name, :through=>:operation, :url=>{:action=>:operation, :controller=>:production}
    t.column :direction_label
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :name, :through=>:warehouse, :url=>{:action=>:warehouse}
  end

  create_kame(:tracking_sales_order_lines, :model=>:sales_order_lines, :conditions=>{:company_id => ['@current_company.id'], :tracking_id=>['session[:current_tracking_id]']}, :order=>'order_id') do |t|
    t.column :number, :through=>:order, :url=>{:action=>:sales_order}    
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :name, :through=>:warehouse, :url=>{:action=>:warehouse}
  end

  def tracking
    return unless @tracking = find_and_check(:trackings)
    session[:current_tracking_id] = @tracking.id
    t3e @tracking.attributes
  end

 
end
