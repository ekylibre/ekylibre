class ManagementController < ApplicationController

  
  include ActionView::Helpers::FormOptionsHelper
  include ActionView::Helpers::NumberHelper
 
  def index
    @deliveries = @current_company.deliveries.find(:all,:conditions=>{:moved_on=>nil})
    @purchases = @current_company.purchase_orders.find(:all, :conditions=>{:moved_on=>nil})
    all_product_stocks = ProductStock.find(:all, :conditions=>{:company_id=>@current_company.id})
    @stock_locations = @current_company.stock_locations
    @product_stocks = []
    for product_stock in all_product_stocks
      @product_stocks << product_stock if product_stock.state == "critic"
    end
    @stock_transfers = @current_company.stock_transfers.find(:all, :conditions=>{:moved_on=>nil}) 
    @payments_to_embank = @current_company.checks_to_embank(-1)
    @embankments_to_lock = @current_company.embankments_to_lock

#     sn = @current_company.subscription_natures.find(:first, :order=>"COALESCE(reduction_rate, 0) DESC")
#     g = Gruff::Line.new(800,200)
#     g.title = sn.name
#     start, finish  = 700, sn.actual_number
#     for x in 0..2
#       months = []
#       f = finish-22*x+1
#       s = f-21
#       for i in s..f
#         months << sn.subscriptions.count(:conditions=>["? between first_number AND last_number", i])
#       end
#       g.data "Du #{s} au #{f}", months
#     end
#     g.write("#{RAILS_ROOT}/public/images/gruff/#{@current_company.id}-test.png")

#     g = Gruff::Line.new(800,200)
#     g.title = sn.name
#     start, finish  = 700, sn.actual_number
#     months = []
#     for i in start..finish
#       months << sn.subscriptions.count(:conditions=>["? between first_number AND last_number", i])
#     end
#     g.data "Du #{start} au #{finish}", months
#     g.write("#{RAILS_ROOT}/public/images/gruff/#{@current_company.id}-test.png")
    

#     g = Gruff::Line.new(800,200)
#     sn = @current_company.subscription_natures.find(:first, :order=>"COALESCE(reduction_rate, 0) DESC")
#     g.title = sn.name
#     for x in 2007..2009
#       months = []
#       12.times do |i|
#         months << sn.subscriptions.count(:conditions=>["started_on BETWEEN ? AND ?", Date.civil(x,i+1,1), Date.civil(x,i+1,1).end_of_month])
#       end
#       g.data x.to_s, months
#     end
#     g.write("#{RAILS_ROOT}/public/images/gruff/#{@current_company.id}-test.png")
  end
  
  
  dyta(:delays, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :active
    t.column :expression
    t.column :comment
    t.action :delay, :image=>:show
    t.action :delay_update
    t.action :delay_delete, :method=>:delete, :confirm=>:are_you_sure
  end

  def delays
  end

  def delay
    @delay = find_and_check(:delay, params[:id])
    @title = {:value=>@delay.name}
  end

  manage :delays
  

  #this method allows to create a graphism
  def statistics
    session[:nb_year] = params[:nb_year]||2
    if request.post?
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
          sales << @current_company.sale_order_lines.sum(:quantity, :conditions=>['product_id=? and created_on BETWEEN ? AND ?', product.id, d.beginning_of_month, d.end_of_month], :joins=>"INNER JOIN sale_orders as s ON s.id=sale_order_lines.order_id").to_f
          d += 1.month
          g.labels[m] = d.month.to_s # t('date.abbr_month_names')[d.month].to_s
        end
        g.data('N'+(x>0 ? '-'+x.to_s : '').to_s, sales) # +d.year.to_s
      end

      dir = "#{RAILS_ROOT}/public/images/gruff/#{@current_company.code}"
      @graph = "management-statistics-#{product.code}-#{rand.to_s[2..-1]}.png"
      
      File.makedirs dir unless File.exists? dir
      g.write(dir+"/"+@graph)

    elsif request.put?
      data = {}
      mode = params[:mode].to_s.to_sym
      source = params[:source].to_s.to_sym
      query = if source == :invoice
        "SELECT product_id, sum(sol.#{mode}) AS total FROM invoice_lines AS sol JOIN invoices AS so ON (sol.invoice_id=so.id) WHERE created_on BETWEEN ? AND ? GROUP BY product_id"
      else
        "SELECT product_id, sum(sol.#{mode}) AS total FROM sale_order_lines AS sol JOIN sale_orders AS so ON (sol.order_id=so.id) WHERE state != 'E' AND created_on BETWEEN ? AND ? GROUP BY product_id"
      end
      start = (Date.today - params[:nb_years].to_i.year).beginning_of_month
      finish = Date.today.end_of_month
      date = start
      header = [t('activerecord.models.product')]
      puts [start, finish].inspect
      while date <= finish
        # puts date.inspect
        # raise Exception.new(t('date.month_names').inspect)
        # period = '="'+t('date.month_names')[date.month]+" "+date.year.to_s+'"'
        period = '="'+date.year.to_s+" "+date.month.to_s+'"'
        header << period
        for product in @current_company.products.find(:all, :select=>"products.*, total", :joins=>ActiveRecord::Base.send(:sanitize_sql_array, ["LEFT JOIN (#{query}) AS sold ON (products.id=product_id)", date.beginning_of_month, date.end_of_month]), :order=>"product_id")
          data[product.name] ||= {}
          data[product.name][period] = product.total
        end
        date += 1.month
      end

      csv_data = FasterCSV.generate do |csv|
        csv << header
        for k in data.keys.sort
          row = [k]
          header.size.times {|i| row << number_to_currency(data[k][header[i+1]], :separator=>',', :delimiter=>' ', :unit=>'', :precision=>2) }
          csv << row
        end
      end
      
      send_data csv_data, :type=>Mime::CSV, :disposition=>'inline', :filename=>::I18n.translate('activerecord.models.product')+'.csv'
    end



  end
    
  #

  dyta(:inventories, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :date
    t.column :changes_reflected, :label=>tc('changes_reflected')
    t.column :label, :through=>:employee
    t.column :comment
    t.action :inventory_print
    t.action :inventory_reflect, :if=>'RECORD.company.inventories.find_all_by_changes_reflected(false).size <= 1 and RECORD.changes_reflected == false'
    t.action :inventory_update,  :if=>'RECORD.changes_reflected == false'
    t.action :inventory_delete, :method=>:post, :confirm=>:are_you_sure, :if=>'RECORD.changes_reflected == false'
  end

  dyta(:inventory_lines_create, :model=>:product_stocks, :conditions=>{:company_id=>['@current_company.id'] }, :per_page=>1000, :order=>{'sort'=>'location_id', 'dir'=>'asc'}) do |t|
    t.column :name, :through=>:location
    t.column :name, :through=>:product
    t.column :shelf_name, :through=>:product, :label=>tc('shelf')
    t.column :current_real_quantity, :label=>tc('theoric_quantity')
    t.textbox :current_real_quantity
  end

  dyta(:inventory_lines_update, :model=>:inventory_lines, :conditions=>{:company_id=>['@current_company.id'], :inventory_id=>['session[:current_inventory]'] }, :per_page=>1000,:order=>{ 'sort'=>'location_id', 'dir'=>'asc'}) do |t|
    t.column :name, :through=>:location
    t.column :name, :through=>:product
    t.column :shelf_name, :through=>:product, :label=>tc('shelf')
    t.column :theoric_quantity
    t.textbox :validated_quantity
  end

  def inventories
  end
  
  def inventory_create
    flash[:notice] = tc(:you_should_lock_your_old_inventories) if @current_company.inventories.find_all_by_changes_reflected(false).size >= 1
    @inventory = Inventory.new(:employee_id=>@current_user.employee.nil? ? 0 : @current_user.employee.id)
    if request.post?
      @inventory = Inventory.new(params[:inventory])
      @inventory.company_id = @current_company
      @inventory.save
      params[:inventory_lines_create].collect{|x| ProductStock.find_by_id_and_company_id(x[0], @current_company.id).to_inventory_line(x[1][:current_real_quantity].to_f, @inventory.id) }
      redirect_to :action=>:inventories
    end
  end

  def inventory_reflect
    return unless @inventory = find_and_check(:inventories, params[:id])
    redirect_to :action=>:inventories if @inventory.update_attributes(:changes_reflected=>true)
  end

  def inventory_update
    return unless @inventory = find_and_check(:inventories, params[:id])
    session[:current_inventory] = @inventory.id
    if request.post? and !@inventory.changes_reflected
      params[:inventory_lines_update].collect{|x| InventoryLine.find_by_id_and_company_id(x[0], @current_company.id).update_attributes!(:validated_quantity=>x[1][:validated_quantity].to_f) }
      @inventory.update_attributes(params[:inventory])
      redirect_to :action=>:inventories
    end
  end

  def inventory_delete
    return unless @inventory = find_and_check(:inventories, params[:id])
    if request.post? and !@inventory.changes_reflected
      redirect_to_back if @inventory.destroy
    end
  end

  def inventory_print
    return unless @inventory = find_and_check(:inventories, params[:id])
    print(@inventory, :filename=>tc('inventory')+" "+@inventory.date.to_s)
  end

  
  dyta(:all_invoices, :model=>:invoices, :conditions=>search_conditions(:invoices, :number), :line_class=>'RECORD.status', :default_order=>"created_on DESC, number DESC") do |t|
    t.column :number, :url=>{:action=>:invoice}
    t.column :full_name, :through=>:client
    t.column :created_on
    t.column :amount
    t.column :amount_with_taxes
    t.column :credit
    #t.action :invoice_to_accountancy
   
    t.action :invoice_print

    t.action :invoice_cancel, :if=>"RECORD.creditable\?"
  end


  def invoices
   @key = params[:key]||session[:invoice]
   session[:invoice_key] = @key
   #all_invoices_list({:attributes=>[:number], :key=>@key}.merge(params))
  end

  
  #
  # def invoice_to_accountancy
#     @invoice = find_and_check(:invoice, params[:id])
#     @invoice.to_accountancy
#     redirect_to :action=>:invoices
#   end


  dyta(:credit_lines, :model=>:invoice_lines, :conditions=>{:invoice_id=>['session[:invoice_id]']}) do |t|
    t.column :name, :through=>:product
    t.column :amount_with_taxes, :through=>:price, :label=>::I18n.t('activerecord.attributes.price.amount_with_taxes')
    t.column :quantity
    t.column :credited_quantity, :datatype=>:decimal
    t.check  :validated, :value=>"true", :label=>'OK'
    t.textbox :quantity, :value=>"RECORD.uncredited_quantity", :size=>6
  end

  def invoice_cancel
    return unless @invoice = find_and_check(:invoices, params[:id])
    session[:invoice_id] = @invoice.id
#    @invoice_cancel = Invoice.find_by_origin_id_and_company_id(@invoice.id, @current_company.id)
#     if @invoice_cancel.nil?
#       @invoice_cancel = Invoice.new(:origin_id=>@invoice.id, :client_id=>@invoice.client_id, :credit=>true, :company_id=>@current_company.id)
#       @invoice_cancel_lines = @invoice.lines.collect{|x| InvoiceLine.new(:origin_id=>x.id, :product_id=>x.product_id, :price_id=>x.price_id, :quantity=>0, :company_id=>@current_company.id, :order_line_id=>x.order_line_id)}
#     else
#       @invoice_cancel_lines = @invoice_cancel.lines
#     end
    if request.post?
      ActiveRecord::Base.transaction do
        # session[:errors] = []
        params[:credit_lines] ||= {}
#         empty = true
#         for l, attrs in params[:credit_lines]
#           empty = false if attrs[:quantity].to_f>0
#         end
#         if empty
#           flash[:error] = tc('messages.need_quantities_to_cancel_an_invoice')
#           return
#         end
        @credit = Invoice.new(:origin_id=>@invoice.id, :client_id=>@invoice.client_id, :credit=>true, :company_id=>@current_company.id)
        saved = @credit.save
        if saved
          for line in @invoice.lines
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
                    credit_line.errors.each_full do |msg|
                      @credit.errors.add_to_base(msg)
                    end
                  end
                  puts ">>>>>>>>>>>>>>>>><>>>>>>>>>>>>>>>>>>>>>> "+@credit.inspect
                end
              end
            end
          end
          
          if @credit.reload.amount_with_taxes == 0
            puts @credit.inspect
            flash[:error] = tc('messages.need_quantities_to_cancel_an_invoice')
            raise ActiveRecord::Rollback 
          end

#           for cancel_line in @invoice_cancel_lines
#             cancel_line.quantity -= (params[:invoice_cancel_line][cancel_line.origin_id.to_s][:quantity].to_f)
#             cancel_line.invoice_id = @invoice_cancel.id
#             saved = false unless cancel_line.save
#           end
        end
        if saved
          redirect_to :action=>:invoice, :id=>@credit.id
        else
#           session[:errors] = []
#           for line in @invoice_cancel_lines
#             session[:errors] << line.errors.full_messages if !line.errors.full_messages.empty?
#           end
          # redirect_to :action=>:invoice_cancel, :id=>@invoice.id
          raise ActiveRecord::Rollback
        end
      end
    end
    @title = {:value=>@invoice.number}
  end
   

  dyta(:invoice_credit_lines, :model=>:invoice_lines, :conditions=>{:company_id=>['@current_company.id'], :invoice_id=>['session[:current_invoice]']}) do |t|
    t.column :name, :through=>:product, :url=>{:action=>:product}
    t.column :amount, :through=>:price
    t.column :amount_with_taxes, :through=>:price, :label=>tc('price_amount_with_taxes')
    t.column :quantity
    t.column :amount
    t.column :amount_with_taxes
  end

  dyta(:credits, :model=>:invoices, :conditions=>{:company_id=>['@current_company.id'], :origin_id=>['session[:current_invoice]'] }) do |t|
    t.column :number, :url=>{:action=>:invoice}
    t.column :full_name, :through=>:client
    t.column :created_on
    t.column :amount
    t.column :amount_with_taxes
  end


  def invoice
    @invoice = find_and_check(:invoice, params[:id])
    session[:current_invoice] = @invoice.id
    @title = {:number=>@invoice.number}
  end

  def invoice_print
    return unless invoice = find_and_check(:invoice, params[:id])
    print(invoice, :filename=>invoice.label)
  end


  def self.prices_conditions(options={})
    code = ""
    code += " if session[:entity_id] == 0 \n " 
    code += " conditions = ['company_id = ? AND active = ?', @current_company.id, true] \n "
    code += " else \n "
    code += " conditions = ['company_id = ? AND entity_id = ?  AND active = ?', @current_company.id,session[:entity_id], true]"
    code += " end \n "
    code += " conditions \n "
    code
  end
  
  dyta(:prices, :conditions=>prices_conditions) do |t|
    t.column :name, :through=>:product, :url=>{:action=>:product}
    t.column :full_name, :through=>:entity
    t.column :name, :through=>:category, :label=>tc(:category), :url=>{:controller=>:relations, :action=>:entity_category}
    t.column :amount
    t.column :amount_with_taxes
    t.column :default
    t.column :range
    t.action :price_delete, :method=>:delete, :confirm=>:are_you_sure
  end
  
  
  def prices
    @modes = ['all', 'client', 'supplier']
    @suppliers = @current_company.entities.find(:all,:conditions=>{:supplier=>true})
    session[:entity_id] = 0
    if request.post?
      mode = params[:price][:mode]
      if mode == "supplier"
        session[:entity_id] = params[:price][:supply].to_i
      elsif mode == "client"
        session[:entity_id] = @current_company.entity_id
      else
        session[:entity_id] = 0
      end
    end
  end
  
  def price_create
    @mode = (params[:mode]||"sales").to_sym 

    if @mode == :sales
      @products = Product.find(:all, :conditions=>{:to_sale=>true, :company_id=>@current_company.id}, :order=>:name)
    else 
      @products = Product.find(:all, :conditions=>{:to_purchase=>true, :company_id=>@current_company.id}, :order=>:name)
    end

    if request.post? 
      @price = Price.new(params[:price])
      @price.company_id = @current_company.id
      @price.entity_id = params[:price][:entity_id]||@current_company.entity_id
      if @price.save
        all_safe = true
        if params[:price_tax]
          for tax in params[:price_tax]
            tax = find_and_check(:tax, tax[0])
            @price_tax = @price.taxes.create(:tax_id=>tax.id)
            all_safe = false unless @price_tax.save
          end
        end
        redirect_to_back
      end
    else
      if @current_company.available_products.size<=0
        flash[:message] = tc('messages.need_product_to_create_price')
        redirect_to :action=> :product_create
      elsif !params[:product_id].nil?
   
        @price = Price.new(:product_id=>params[:product_id])
      else
   
        @price = Price.new(:category_id=>session[:category]||0)
      end

      @price.entity_id = params[:entity_id] if params[:entity_id]
    end
    render_form    
  end
  
  def price_delete
    @price = find_and_check(:price, params[:id])
    if request.post? or request.delete?
      @price.update_attributes(:active=>false)
    end
    redirect_to_current
  end
  

  def prices_export
    @products = Product.find(:all, :conditions=>{:company_id=>@current_company.id, :active=>true})
    @entity_categories = EntityCategory.find(:all, :conditions=>{:company_id=>@current_company.id, :deleted=>false})
    
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
        flash[:warning]=tc(:you_must_select_a_file_to_import)
        redirect_to :action=>:prices_import
      else
        file = params[:csv_file][:path]
        name = "MES_TARIFS.csv"
        @entity_categories = []
        @available_prices = []
        @unavailable_prices = []
        i = 0
        File.open("#{RAILS_ROOT}/#{name}", "w") { |f| f.write(file.read)}
        FasterCSV.foreach("#{RAILS_ROOT}/#{name}") do |row|
          if i == 0
            x = 2
            #raise Exception.new row.inspect
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
            @product = Product.find_by_code_and_company_id(row[0], @current_company.id) ## Cas ou pdt existe pas
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
        ##Fin boucle FasterCSV
        if @unavailable_prices.empty?
          for price in @available_prices
            if price.id.nil?
              puts price.inspect
              Price.create!(price.attributes)
            else
              price.update_attributes(price.attributes)
            end
            flash[:notice]=tc(:import_succeed)
          end
        end
      end
    end
    
  end
  
  dyta(:product_prices, :conditions=>{:company_id=>['@current_company.id'], :product_id=>['session[:product_id]'], :active=>true}, :model=>:prices) do |t|
    t.column :name, :through=>:entity
    t.column :name, :through=>:category, :url=>{:controller=>:relations, :action=>:entity_category}

    t.column :amount
    t.column :amount_with_taxes
    t.column :default
    t.column :range
    t.action :price_delete, :method=>:delete, :confirm=>:are_you_sure
  end

  dyta(:product_components, :conditions=>{:company_id=>['@current_company.id'], :product_id=>['session[:product_id]'], :active=>true}) do |t|
    t.column :name
    t.action :product_component_update
    t.action :product_component_delete, :method=>:delete, :confirm=>:are_you_sure
  end

  def product_component_create
    @product = find_and_check(:products, session[:product_id])
    if request.post?
      @product_component = ProductComponent.new(params[:product_component])
      @product_component.company_id = @current_company.id
      @product_component.product_id = @product.id
      redirect_to :action=>:product, :id=>session[:product_id] if @product_component.save
    else
      @product_component = ProductComponent.new(:quantity=>1.0)
    end
    @title = {:value=>@product.name}
    render_form
  end
  
  def product_component_update
    @product_component = find_and_check(:product_component, params[:id])
    @product = find_and_check(:product, session[:product_id])
    if request.post?
      redirect_to :action=>:product, :id=>@product.id if @product_component.update_attributes!(params[:product_component])
    end
    @title = {:product=>@product.name, :component=>@product_component.name}
    render_form
  end

  def product_component_delete
    if request.post? or request.delete?
      @product_component = find_and_check(:product_component, params[:id])
      @product_component.update_attributes!(:active=>false)
      redirect_to :action=>:product, :id=>session[:product_id]
    end
  end


  def self.products_conditions(options={})
    code = ""
    code += "conditions = [ \" company_id = ? AND (code ILIKE ? OR name ILIKE ?) AND active = ? \" , @current_company.id, '%'+session[:product_key]+'%', '%'+session[:product_key]+'%', session[:product_active]] \n"
    code += "if session[:product_shelf_id].to_i != 0 \n"
    code += "conditions[0] += \" AND shelf_id = ?\" \n" 
    code += "conditions << session[:product_shelf_id].to_i \n"
    code += "end \n"
    code += "conditions \n"
    code
  end

  #dyta(:products, :conditions=>search_conditions(:products, :products=>[:code, :name])) do |t|
  dyta(:products, :conditions=>products_conditions) do |t|
    t.column :number
    t.column :name, :through=>:shelf, :url=>{:action=>:shelf}
    t.column :name, :url=>{:action=>:product}
    t.column :code
    t.column :description
    #t.column :active
    t.action :product, :image=>:show
    t.action :product_update
    t.action :product_delete, :method=>:delete, :confirm=>:are_you_sure
  end
    
  def products
    @stock_locations = StockLocation.find_all_by_company_id(@current_company.id)
    session[:product_active] = true if session[:product_active].nil?
    if @stock_locations.size < 1
      flash[:warning]=tc('need_stocks_location_to_create_products')
      redirect_to :action=>:stock_location_create
    end
    @key = params[:key]||session[:product_key]||" "
    session[:product_key] = @key
    if request.post?
      session[:product_active] = params[:product_active].nil? ? false : true
      session[:product_shelf_id] = params[:product].nil? ? 0 : params[:product][:shelf_id].to_i
    end
  end
  
  def product
    @product = find_and_check(:product, params[:id])
    session[:product_id] = @product.id
    all_product_stocks = ProductStock.find(:all, :conditions=>{:company_id=>@current_company.id})
    @product_stocks = []
    @stock_locations = @current_company.stock_locations
    for product_stock in all_product_stocks
      @product_stocks << product_stock if product_stock.product_id == @product.id
    end
    @title = {:value=>@product.name}
  end

  def change_quantities
    @location = ProductStock.find(:first, :conditions=>{:location_id=>params[:product_stock_location_id], :company_id=>@current_company.id, :product_id=>session[:product_id]} ) 
    if @location.nil?
      @location = ProductStock.new(:quantity_min=>1, :quantity_max=>0, :critic_quantity_min=>0)
    end
  end

  def product_create
    @stock_locations = StockLocation.find_all_by_company_id(@current_company.id)
    if request.post?
      #raise Exception.new params.inspect
      @product = Product.new(params[:product])
      @product.duration = params[:product][:duration]
      @product.company_id = @current_company.id
      @product_stock = ProductStock.new(params[:product_stock])
      ActiveRecord::Base.transaction do
        saved = @product.save
        if params[:product][:manage_stocks] == "1"
          if saved
            @product_stock.product_id = @product.id
            @product_stock.company_id = @current_company.id
            saved = false unless @product_stock.save!
            @product_stock.errors.each_full do |msg|
              @product.errors.add_to_base(msg)
            end
          end
        end 
        if saved
          redirect_to_back
        else
          raise ActiveRecord::Rollback
        end
      end
    else 
      @product = Product.new
      @product.nature = Product.natures.first[1]
      @product.supply_method = Product.supply_methods.first[1]
      @product_stock = ProductStock.new
    end
    render_form
  end
  
  def product_update
    @product = find_and_check(:product, params[:id])
    session[:product_id] = @product.id
    @stock_locations = StockLocation.find_all_by_company_id(@current_company.id)
    if !@product.manage_stocks
      @product_stock = ProductStock.new
    else
      @product_stock = ProductStock.find(:first, :conditions=>{:company_id=>@current_company.id ,:product_id=>@product.id} )||ProductStock.new 
    end
    if request.post?
      ActiveRecord::Base.transaction do
        saved = @product.update_attributes(params[:product])
        ## @product_stock.  id.  nil?
        if saved
          if @product_stock.id.nil? and params[:product][:manage_stocks] == "1"
            @product_stock = ProductStock.new(params[:product_stock])
            @product_stock.product_id = @product.id
            @product_stock.company_id = @current_company.id 
            save = false unless @product_stock.save
            #raise Exception.new "ghghgh"
          elsif !@product_stock.id.nil? and @stock_locations.size > 1
            save = false unless @product_stock.add_or_update(params[:product_stock],@product.id)
          else
            #save = false unless @product_stock.update_attributes(params[:product_stock])
            save = true
          end
          @product_stock.errors.each_full do |msg|
            @product.errors.add_to_base(msg)
          end
        end
        raise ActiveRecord::Rollback unless saved  
      end
      redirect_to :action=>:product, :id=>@product.id
    end
    @title = {:value=>@product.name}
    render_form()
  end
  
  def product_delete
    @product = find_and_check(:product, params[:id])
    if request.post? or request.delete?
      redirect_to :back if @product.delete
    end
  end


  def products_search
    if request.post?
    else
      redirect_to :action=>:products
    end
  end



  dyta(:purchase_orders, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :number ,:url=>{:action=>:purchases_products}
    t.column :full_name, :through=>:supplier, :url=>{:controller=>:relations, :action=>:entity}
    t.column :address, :through=>:dest_contact
    t.column :shipped
    t.column :invoiced
    t.column :amount
    t.column :amount_with_taxes
    t.action :purchases_print
  end


  dyli(:entities, [:code, :full_name], :conditions => {:company_id=>['@current_company.id']})
  dyli(:suppliers, [:code, :full_name],  :model=>:entities, :conditions => {:company_id=>['@current_company.id'], :supplier=>true })
  dyli(:contacts, [:address], :conditions => { :company_id=>['@current_company.id'], :entity_id=>['@current_company.entity_id']})

  def purchase_orders
  end

  def purchases_print
    @order    = find_and_check(:purchase_order, params[:id])
    @supplier = @order.supplier
    @client   = @current_company.entity
    print(@order, :archive=>false)
  end

  def purchases_new
    redirect_to :action=>:purchase_order_create
  end

  def purchase_order_create
    if request.post?
      @purchase_order = PurchaseOrder.new(params[:purchase_order])
      @purchase_order.company_id = @current_company.id
      redirect_to :action=>:purchases_products, :id=>@purchase_order.id if @purchase_order.save
    else
      @purchase_order = PurchaseOrder.new(:planned_on=>Date.today)
      session[:current_entity] = @purchase_order.id
    end
    render_form
  end

  dyta(:purchase_order_lines, :conditions=>{:company_id=>['@current_company.id'], :order_id=>['session[:current_purchase]']}) do |t|
    t.column :name, :through=>:product, :url=>{:action=>:product}
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :amount, :through=>:price
    t.column :amount
    t.column :amount_with_taxes
    t.action :purchase_order_line_update, :if=>'RECORD.order.shipped == false'
    t.action :purchase_order_line_delete,  :image=>:delete, :method=>:post, :confirm=>:are_you_sure, :if=>'RECORD.order.shipped == false'
  end

  def purchases_products
    @purchase_order = find_and_check(:purchase_order, params[:id])
    session[:current_purchase] = @purchase_order.id
    #purchase_order_lines_list params
    if request.post?
      @purchase_order.stocks_moves_create
      @purchase_order.update_attributes(:shipped=>true)
    end
    @title = {:value=>@purchase_order.number,:name=>@purchase_order.supplier.full_name}
  end

  def price_find
    if !params[:purchase_order_line_price_id].blank?
      price = find_and_check(:price, params[:purchase_order_line_price_id])
      @price_amount = Price.find_by_id(price.id).amount
      if price.tax.amount == 0.0210
        @tax_id = 1
      elsif price.tax.amount == 0.0550
        @tax_id = 2
      else 
        @tax_id = 3
      end
    else
      @price_amount = 0 
      @tax_id = 3
    end
  end
  
  def calculate_price(exist)
    if exist
      @purchase_order_line.quantity += params[:purchase_order_line][:quantity].to_d
      @purchase_order_line.amount = @price.amount*@purchase_order_line.quantity
      @purchase_order_line.amount_with_taxes = @price.amount_with_taxes*@purchase_order_line.quantity
    else
      @purchase_order_line.amount = @price.amount*params[:purchase_order_line][:quantity].to_d
      @purchase_order_line.amount_with_taxes = @price.amount_with_taxes*params[:purchase_order_line][:quantity].to_d 
    end
  end


  def purchase_order_line_create
    @stock_locations = @current_company.stock_locations
    @purchase_order = PurchaseOrder.find_by_id_and_company_id(session[:current_purchase], @current_company.id)
    if @stock_locations.empty?
      flash[:warning]=tc(:need_stock_location_to_create_purchase_order_line)
      redirect_to :action=>:stock_location_create
    elsif @purchase_order.shipped == true
      flash[:warning]=tc(:impossible_to_add_lines_to_purchase)
      redirect_to :action=>:purchases_products, :id=>@purchase_order.id
    else
      @price = Price.new
      if request.post?
        @purchase_order_line = @current_company.purchase_order_lines.find(:first, :conditions=>{:price_id=>params[:purchase_order_line][:price_id], :order_id=>session[:current_purchase]})
        if @purchase_order_line
          @purchase_order_line.quantity += params[:purchase_order_line][:quantity].to_d
        else
          @purchase_order_line = PurchaseOrderLine.new(params[:purchase_order_line])
          @purchase_order_line.company_id = @current_company.id
          @purchase_order_line.order_id = session[:current_purchase]      
          price = find_and_check(:price, params[:purchase_order_line][:price_id]).change(params[:price][:amount], params[:price][:tax_id])
          @purchase_order_line.product_id = price.product_id
          @purchase_order_line.price_id = price.id
        end
        redirect_to :action=>:purchases_products, :id=>session[:current_purchase] if @purchase_order_line.save
      else
        @purchase_order_line = PurchaseOrderLine.new
        @purchase_order_line.order_id = session[:current_purchase] 
      end
      render_form
    end
  end
  
  def purchase_order_line_update
    @update = true
    @purchase_order_line = find_and_check(:purchase_order_line, params[:id])
    @price = find_and_check(:price, @purchase_order_line.price_id)
    if request.post?
      params[:purchase_order_line][:company_id] = @current_company.id
      if @purchase_order_line.update_attributes(params[:purchase_order_line])  
        @update = false
        redirect_to :action=>:purchases_products, :id=>@purchase_order_line.order_id  
      end
    end
    render_form
  end
  
  def purchase_order_line_delete
    @purchase_order_line = find_and_check(:purchase_order_line, params[:id])
    if request.post? or request.delete?
      redirect_to :back  if @purchase_order_line.destroy
    end
  end
  
  def self.sales_conditions
    code = ""
    code += "conditions = ['company_id = ? ', @current_company.id ] \n "
    code += "unless session[:sale_order_state].blank? \n "
    code += "  if session[:sale_order_state] == 'current' \n "
    code += "    conditions[0] += \" AND state != 'C' \" \n " 
    code += "  elsif session[:sale_order_state] == 'unpaid' \n "
    code += "    conditions[0] += \"AND state NOT IN('C','E') AND parts_amount < amount_with_taxes\" \n "
    code += "  end\n "
    code += "end\n "
    code += "conditions\n "
    code
  end

  dyta(:sale_orders, :conditions=>sales_conditions,:order=>{'sort'=>'created_on','dir'=>'desc'}, :line_class=>'RECORD.status' ) do |t|
    t.column :number, :url=>{:action=>:sale_order_lines}
    #t.column :name, :through=>:nature#, :url=>{:action=>:sale_order_nature}
    t.column :created_on
    t.column :full_name, :through=>:client, :url=>{:controller=>:relations, :action=>:entity}
    t.column :code, :through=>:client, :url=>{:controller=>:relations, :action=>:entity}, :label=>tc('client_code')
    t.column :text_state
    t.column :amount
    t.column :amount_with_taxes
    t.action :sale_order_print
    t.action :sale_order_delete , :method=>:post, :if=>'RECORD.estimate? ', :confirm=>tc(:are_you_sure)
  end
  
  def sale_order_delete
    @sale_order = find_and_check(:sale_order, params[:id])
    if request.post? or request.delete?
      if @sale_order.estimate?
        @sale_order.destroy
      else
        flash[:warning]=tc('sale_order_can_not_be_deleted')
      end
      redirect_to_back
    end
  end
  
  def sale_orders
    #raise Exception.new session[:sale_order_state].inspect
    session[:sale_order_state] ||= "all"
    if request.post?
      #raise Exception.new params.inspect
      session[:sale_order_state] = params[:sale_order][:state]
    end
  end
  
  dyta(:sale_lines, :conditions=>{:company_id=>['@current_company.id'], :order_id=>['session[:current_sale_order]']},:model=>:sale_order_lines,:empty=>true) do |t|
    t.column :name, :through=>:product
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :amount, :through=>:price, :label=>tc(:price)
    t.column :amount
    t.column :amount_with_taxes
  end

  dyta(:deliveries, :conditions=>{:company_id=>['@current_company.id'], :order_id=>['session[:current_sale_order]']}, :children=>:lines) do |t|
    t.column :address, :through=>:contact, :children=>:product_name, :label=>"Livraison"
    t.column :planned_on, :children=>false
    t.column :moved_on, :children=>false
    t.column :amount
    t.column :amount_with_taxes
  end

  dyta(:invoice_lines, :model=>:invoices, :conditions=>{:company_id=>['@current_company.id'],:sale_order_id=>['session[:current_sale_order]']}, :children=>:lines) do |t|
    t.column :number, :children=>:product_name, :url=>{:action=>:invoice}
    t.column :address, :through=>:contact, :children=>false
    t.column :amount
    t.column :amount_with_taxes
  end
  
#   dyta(:payments, :conditions=>{:company_id=>['@current_company.id'], :order_id=>['session[:current_sale_order]']}, :model=>:payment_parts) do |t|
#     # t.column :payer, :through=>[:payment, :entity], :label=>"Payeur"
#     t.column :payment_way
#     t.column :paid_on, :through=>:payment, :label=>"Réglé le"
#     t.column :amount
#     t.column :amount, :through=>:payment, :label=>"Montant du paiment"
#   end
  
  dyta(:payments, :conditions=>["payments.company_id=? AND payment_parts.order_id=?", ['@current_company.id'], ['session[:current_sale_order]']], :joins=>"JOIN payment_parts ON (payments.id=payment_id)") do |t|
    t.column :id
    t.column :full_name, :through=>:entity
    #t.column :payment_way
    t.column :paid_on
    t.column :amount
    # t.column :amount, :through=>:payment, :label=>"Montant du paiment"
  end
  
  def sale_order
    @sale_order = find_and_check(:sale_order, params[:id])
    session[:current_sale_order] = @sale_order.id
    @title = {:value=>@sale_order.number, :name=>@sale_order.client.full_name} 
  end
  
  dyta(:sale_order_natures, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :active
    t.column :name, :through=>:expiration, :url=>{:action=>:delay}, :label=>"Délai d'expiration"
    t.column :name, :through=>:payment_delay, :url=>{:action=>:delay}, :label=>"Délai de paiement"
    t.column :downpayment
    t.column :downpayment_minimum
    t.column :downpayment_rate
    t.column :comment
    t.action :sale_order_nature_update
    t.action :sale_order_nature_delete, :method=>:delete, :confirm=>:are_you_sure
  end

  def sale_order_natures
  end

  def sale_order_nature
    @sale_order_nature = find_and_check(:sale_order_nature, params[:id])
    @title = {:value=>@sale_order_nature.name}
  end

  def sale_order_nature_create
    if request.post? 
      @sale_order_nature = SaleOrderNature.new(params[:sale_order_nature])
      @sale_order_nature.company_id = @current_company.id
      redirect_to_back if @sale_order_nature.save
    else
      @sale_order_nature = SaleOrderNature.new
    end
    render_form
  end

  def sale_order_nature_update
    @sale_order_nature = find_and_check(:sale_order_nature, params[:id])
    if request.post?
      params[:sale_order_nature][:company_id] = @current_company.id
      redirect_to_back if @sale_order_nature.update_attributes(params[:sale_order_nature])
    end
    @title = {:value=>@sale_order_nature.name}
    render_form
  end

  def sale_order_nature_delete
    @sale_order_nature = find_and_check(:sale_order_nature, params[:id])
    if request.post? or request.delete?
      redirect_to :back if @sale_order_nature.destroy
    end
 end



  def sale_order_contacts
    if @sale_order
      client_id = @sale_order.client_id
    else
      client_id = params[:client_id]||(params[:sale_order]||{})[:client_id]||session[:current_entity]
      client_id = 0 if client_id.blank?
    end
    session[:current_entity] = client_id
    contacts = Contact.find(:all, :conditions=>{:entity_id=> client_id, :company_id=>@current_company.id, :active=>true})  
    @contacts = contacts.collect{|x| [x.address, x.id]}
    render :text=>options_for_select(@contacts) if request.xhr?
  end

  dyli(:clients, [:code, :full_name], :model=>:entities, :conditions => {:company_id=>['@current_company.id'], :client=>true})

  def sale_order_create
    sale_order_contacts
    if request.post?
      @sale_order = SaleOrder.new(params[:sale_order])
      @sale_order.company_id = @current_company.id
      @sale_order.number = ''
      if @sale_order.save
        redirect_to :action=>:sale_order_lines, :id=>@sale_order.id
      end
    else
      #      @sale_order = SaleOrder.find_by_id_and_company_id(params[:id], @current_company.id)
      @sale_order = SaleOrder.new if @sale_order.nil?
      client = @current_company.entities.find_by_id(session[:current_entity])
      session[:current_entity] = (client ? client.id : nil)
      @sale_order.responsible_id = @current_user.employee.id if !@current_user.employee.nil?
      @sale_order.client_id = session[:current_entity]
      @sale_order.letter_format = false
      @sale_order.function_title = tg('letter_function_title')
      @sale_order.introduction = tg('letter_introduction')
      # @sale_order.conclusion = tg('letter_conclusion')
    end
    render_form
  end

  def sale_order_update
    return unless @sale_order = find_and_check(:sale_order, params[:id])
    unless @sale_order.estimate?
      flash[:error] = tc('errors.sale_order_cannot_be_updated')
      redirect_to :action=>:sale_order_lines, :id=>@sale_order.id
      return
    end
    sale_order_contacts
    if request.post?
      if @sale_order.update_attributes(params[:sale_order])
        redirect_to :action=>:sale_order_lines, :id=>@sale_order.id
      end
    end
    @title = {:number=>@sale_order.number}
    render_form
  end




  dyta(:sale_order_lines, :conditions=>{:company_id=>['@current_company.id'], :order_id=>['session[:current_sale_order]']}, :export=>false) do |t|
    #t.column :name, :through=>:product
    t.column :label
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :amount, :through=>:price, :label=>tc('price')
    t.column :amount
    t.column :amount_with_taxes
    t.action :sale_order_line_update, :if=>'RECORD.order.estimate? and RECORD.reduction_origin_id.nil? '
    t.action :sale_order_line_delete, :method=>:delete, :confirm=>:are_you_sure, :if=>'RECORD.order.estimate? and RECORD.reduction_origin_id.nil? '
  end

  dyta(:sale_order_subscriptions, :conditions=>{:company_id=>['@current_company.id'], :sale_order_id=>['session[:current_sale_order]']}, :export=>false, :model=>:subscriptions) do |t|
    t.column :name, :through=>:nature
    t.column :full_name, :through=>:entity, :url=>{:controller=>:relations, :action=>:entity}
    t.column :address, :through=>:contact
    t.column :start
    t.column :finish
    t.column :quantity
    t.action :subscription_update
    t.action :subscription_delete, :method=>:delete, :confirm=>:are_you_sure
  end

  def sale_order_lines
    return unless @sale_order = find_and_check(:sale_order, params[:id])
    session[:current_sale_order] = @sale_order.id
    session[:category] = @sale_order.client.category
    @stock_locations = @current_company.stock_locations
    @entity = @sale_order.client
    @title = {:client=>@entity.full_name, :sale_order=>@sale_order.number}
  end

  def sale_order_confirm
    return unless @sale_order = find_and_check(:sale_orders, params[:id])
    if request.post?
      @sale_order.confirm
      redirect_to :action=>:sale_order_deliveries, :id=>@sale_order.id
    end
  end

  def sale_order_invoice
    return unless @sale_order = find_and_check(:sale_orders, params[:id])
    if request.post?
      ActiveRecord::Base.transaction do
        # raise Exception.new(@sale_order.deliver_and_invoice.errors.inspect)
        raise ActiveRecord::Rollback unless @sale_order.deliver_and_invoice
        redirect_to :action=>:sale_order_summary, :id=>@sale_order.id
        return
      end
    end
    redirect_to :action=>:sale_order_lines, :id=>@sale_order.id
  end


  def sale_order_print
    @sale_order = find_and_check(:sale_order, params[:id])
    if @current_company.default_contact.nil? || @sale_order.client.contacts.size == 0
      entity = @current_company.default_contact.nil? ? @current_company.name : @sale_order.client.full_name
      flash[:warning]=tc(:no_contacts, :name=>entity)
      redirect_to_back
    else
      print(@sale_order, :filename=>@sale_order.label)
    end
  end

  def sale_order_duplicate
    return unless sale_order = find_and_check(:sale_order, params[:id])
    if request.post?
      if copy = sale_order.duplicate(:responsible_id=>@current_user.employee_id)
        redirect_to :action=>:sale_order_lines, :id=>copy.id
        return
      end
    end
    redirect_to_current
  end


#   def add_lines
#     @sale_order_line = @current_company.sale_order_lines.find(:first, :conditions=>{:price_id=>params[:sale_order_line][:price_id], :order_id=>session[:current_sale_order]})
#     if @sale_order_line
#       @sale_order_line.quantity += params[:sale_order_line][:quantity].to_d
#       @sale_order_line.save
#     else
#       @sale_order_line = SaleOrderLine.new(params[:sale_order_line])
#       @sale_order_line.company_id = @current_company.id 
#       @sale_order_line.order_id = session[:current_sale_order]
#       @sale_order_line.product_id = find_and_check(:prices,params[:sale_order_line][:price_id]).product_id
#       @sale_order_line.location_id = @stock_locations[0].id if @stock_locations.size == 1
#     end
#     redirect_to :action=>:sale_order_lines, :id=>session[:current_sale_order]
#     #raise Exception.new @sale_order_line.inspect
#   end
  
  def calculate_sales_price(exist)
    if exist
      @sale_order_line.quantity += params[:sale_order_line][:quantity].to_d
      @sale_order_line.amount = @price.amount*@sale_order_line.quantity
      @sale_order_line.amount_with_taxes = @price.amount_with_taxes*@sale_order_line.quantity
    else
      @sale_order_line.amount = @price.amount*params[:sale_order_line][:quantity].to_d
      @sale_order_line.amount_with_taxes = @price.amount_with_taxes*params[:sale_order_line][:quantity].to_d 
    end
  end

  def subscription_find
    price = find_and_check(:prices, params[:sale_order_line_price_id])
    product = find_and_check(:products, price.product_id)
    if product.nature == "subscrip"
      @subscription = Subscription.new(:product_id=>product.id).init
    end
    #puts @product.inspect
    # raise Exception.new @price.product.inspect
  end

  def subscription_message
    price = find_and_check(:prices, params[:sale_order_line_price_id])
    @product = find_and_check(:products, price.product_id)
  end

  dyli(:all_contacts, [:address], :model=>:contacts, :conditions => {:company_id=>['@current_company.id'], :active=>true})
  
  def sale_order_line_create
    @stock_locations = @current_company.stock_locations
    @sale_order = SaleOrder.find(:first, :conditions=>{:company_id=>@current_company.id, :id=>session[:current_sale_order]})
    @sale_order_line = SaleOrderLine.new(:price_amount=>0.0)
    @subscription = Subscription.new
    if @stock_locations.empty? 
      flash[:warning]=tc(:need_stock_location_to_create_sale_order_line)
      redirect_to :action=>:stock_location_create
      return
    elsif @sale_order.active?
      flash[:warning]=tc(:impossible_to_add_lines)
      redirect_to :action=>:sale_order_lines, :id=>@sale_order.id
      return
    elsif request.post? 
      @sale_order_line = @current_company.sale_order_lines.find(:first, :conditions=>{:price_id=>params[:sale_order_line][:price_id], :order_id=>session[:current_sale_order]})
      if @sale_order_line and params[:sale_order_line][:price_amount].to_d <= 0
        @sale_order_line.quantity += params[:sale_order_line][:quantity].to_d
      else
        @sale_order_line = @sale_order.lines.build(params[:sale_order_line])
        @sale_order_line.location_id = @stock_locations[0].id if @stock_locations.size == 1
        # @sale_order_line.company_id  = @current_company.id
        # @sale_order_line.order_id    = session[:current_sale_order]
        # @sale_order_line.product_id  = find_and_check(:prices,params[:sale_order_line][:price_id]).product_id
      end
      ActiveRecord::Base.transaction do
        saved = @sale_order_line.save
        if saved 
          if @sale_order_line.subscription?
            @subscription = @sale_order_line.new_subscription(params[:subscription])
            saved = false unless @subscription.save
              @sale_order_line.errors.each_full do |msg|
              @subscription.errors.add_to_base(msg)
            end
          end
          raise ActiveRecord::Rollback unless saved
          redirect_to :action=>:sale_order_lines, :id=>@sale_order.id 
        end
      end
    end
    render_form
  end
  
  def sale_order_line_update
    @stock_locations = @current_company.stock_locations
    @sale_order = SaleOrder.find(:first, :conditions=>{:company_id=>@current_company.id, :id=>session[:current_sale_order]})
    @sale_order_line = find_and_check(:sale_order_line, params[:id])
    @subscription = @current_company.subscriptions.find(:first, :conditions=>{:sale_order_id=>@sale_order.id}) || Subscription.new
    #raise Exception.new @subscription.inspect
    if request.post?
      # params[:sale_order_line].delete(:company_id)
      # params[:sale_order_line].delete(:order_id)
      redirect_to_back if @sale_order_line.update_attributes(params[:sale_order_line])
    end
    @title = {:value=>@sale_order_line.product.name}
    render_form
  end

  def sale_order_line_delete
    @sale_order_line = find_and_check(:sale_order_line, params[:id])
    if request.post? or request.delete?
      redirect_to :back if @sale_order_line.destroy
    end
  end

  dyta(:sale_order_deliveries, :model=>:deliveries, :children=>:lines, :conditions=>{:company_id=>['@current_company.id'], :order_id=>['session[:current_sale_order]']}) do |t|
    t.column :address, :through=>:contact, :children=>:product_name
    t.column :planned_on, :children=>false
    t.column :moved_on, :children=>false
    t.column :number, :through=>:invoice, :url=>{:action=>:invoice}, :children=>false
    t.column :quantity
    t.column :amount
    t.column :amount_with_taxes
    #t.action :sale_order_delivery_update, :if=>'RECORD.invoice_id.nil? and RECORD.moved_on.nil? '
    t.action :sale_order_delivery_update, :if=>'!RECORD.order.invoiced'
    #t.action :delivery_delete, :if=>'RECORD.invoice_id.nil? and RECORD.moved_on.nil? ', :method=>:post, :confirm=>:are_you_sure
    t.action :delivery_delete, :if=>'!RECORD.order.invoiced', :method=>:delete, :confirm=>:are_you_sure
  end

  
#   dyta(:deliveries_to_invoice, :model=>:deliveries, :children=>:lines,   :conditions=>['company_id = ? AND order_id = ? AND invoice_id IS NULL', ['@current_company.id'], ['session[:current_sale_order]']]) do |t|
#     t.column :address, :through=>:contact, :children=>:product_name
#     t.column :planned_on, :children=>false
#     t.column :moved_on, :children=>false
#     t.column :quantity
#     t.column :amount
#     t.column :amount_with_taxes
#     t.check :invoiceable, :value=>true
#   end


 
  dyta(:undelivered_quantities, :model=>:sale_order_lines, :conditions=>{:company_id=>['@current_company.id'], :order_id=>['session[:current_sale_order]'], :reduction_origin_id=>nil}) do |t|
    t.column :name, :through=>:product
    t.column :amount, :through=>:price, :label=>tc('price')
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :amount
    t.column :amount_with_taxes
    t.column :undelivered_quantity
  end



  def sale_order_deliveries
    return unless @sale_order = find_and_check(:sale_order, params[:id])
    session[:current_sale_order] = @sale_order.id
    if @sale_order.deliveries.size <= 0
      redirect_to :action=>:sale_order_delivery_create
    elsif @sale_order.lines.size <= 0
      flash[:warning]=tc(:no_lines_found)
      redirect_to :action=>:sale_order_lines, :id=>session[:current_sale_order]
    else
      @undelivered_amount = @sale_order.undelivered :amount_with_taxes
    end
  end


  def sum_calculate
    @sale_order = find_and_check(:sale_orders,session[:current_sale_order])
    @sale_order_lines = @sale_order.lines
    @delivery = Delivery.new(params[:delivery])
    @delivery_lines = DeliveryLine.find_all_by_company_id_and_delivery_id(@current_company.id, session[:current_delivery])
    for line in  @sale_order_lines
      if params[:delivery_line][line.id.to_s]
        @delivery.amount_with_taxes += (line.price.amount_with_taxes*(params[:delivery_line][line.id.to_s][:quantity]).to_f)
        @delivery.amount += (line.price.amount*(params[:delivery_line][line.id.to_s][:quantity]).to_f)
      end
    end
    @delivery.amount = @delivery.amount.round(2)
    @delivery.amount_with_taxes = @delivery.amount_with_taxes.round(2)
  end

  def sale_order_delivery_create
    @delivery_form = "delivery_form"
    @sale_order = find_and_check(:sale_orders,session[:current_sale_order])
    @sale_order_lines = @sale_order.lines
    if @sale_order_lines.empty?
      flash[:warning]=lc(:no_lines_found)
      redirect_to :action=>:sale_order_deliveries, :id=>session[:current_sale_order]
    end
    @delivery_lines =  @sale_order_lines.find_all_by_reduction_origin_id(nil).collect{|x| DeliveryLine.new(:order_line_id=>x.id, :quantity=>x.undelivered_quantity)}
    @delivery = Delivery.new(:amount=>@sale_order.undelivered("amount"), :amount_with_taxes=>@sale_order.undelivered("amount_with_taxes"), :planned_on=>Date.today, :transporter_id=>@sale_order.transporter_id)
    session[:current_delivery] = @delivery.id
    @contacts = Contact.find(:all, :conditions=>{:company_id=>@current_company.id, :active=>true, :entity_id=>@sale_order.client_id})
    
    if request.post?
      @delivery = Delivery.new(params[:delivery])
      @delivery.order_id = @sale_order.id
      @delivery.company_id = @current_company.id
      
      ActiveRecord::Base.transaction do
        saved = @delivery.save
        if saved
          for line in @sale_order_lines.find_all_by_reduction_origin_id(nil)
            if params[:delivery_line][line.id.to_s][:quantity].to_f > 0
            delivery_line = DeliveryLine.new(:order_line_id=>line.id, :delivery_id=>@delivery.id, :quantity=>params[:delivery_line][line.id.to_s][:quantity].to_f, :company_id=>@current_company.id)
            saved = false unless delivery_line.save
            delivery_line.errors.each_full do |msg|
              @delivery.errors.add_to_base(msg)
            end
            end
          end
        end
        raise ActiveRecord::Rollback unless saved  
        redirect_to :action=>:sale_order_deliveries, :id=>session[:current_sale_order] 
      end
    end
    render_form(:id=>@delivery_form)
  end
  
  def sale_order_delivery_update
    @delivery_form = "delivery_form"
    @delivery =  find_and_check(:delivery, params[:id])
    session[:current_delivery] = @delivery.id
    @contacts = Contact.find(:all, :conditions=>{:company_id=>@current_company.id, :entity_id=>@delivery.order.client_id})
    @sale_order = find_and_check(:sale_orders,session[:current_sale_order])
    @sale_order_lines = SaleOrderLine.find(:all,:conditions=>{:company_id=>@current_company.id, :order_id=>session[:current_sale_order]})
    @delivery_lines = DeliveryLine.find(:all,:conditions=>{:company_id=>@current_company.id, :delivery_id=>@delivery.id})
    if request.post?
      ActiveRecord::Base.transaction do
        saved = @delivery.update_attributes(params[:delivery])
        if saved
          for line in @delivery_lines
            saved = false unless line.update_attributes(:quantity=>params[:delivery_line][line.order_line.id.to_s][:quantity])
            line.errors.each_full do |msg|
              @delivery.errors.add_to_base(msg)
            end
          end
        end
        raise ActiveRecord::Rollback unless saved
        redirect_to :action=>:sale_order_deliveries, :id=>session[:current_sale_order] 
      end
    end
    render_form(:id=>@delivery_form)
  end
 

  def delivery_delete
    @delivery = find_and_check(:deliveries, params[:id])
    if request.post? or request.delete?
      redirect_to_back if @delivery.destroy
    end
  end

  dyta(:delivery_modes, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :code
    t.column :comment
    t.action :delivery_mode_update
    t.action :delivery_mode_delete, :method=>:delete, :confirm=>:are_you_sure
  end

  def delivery_modes
  end

  def delivery_mode_create
    @delivery_mode = DeliveryMode.new
    if request.post?
      @delivery_mode = DeliveryMode.new(params[:delivery_mode])
      @delivery_mode.company_id = @current_company.id
      redirect_to_back if @delivery_mode.save
    end
    render_form
  end

  def delivery_mode_update
    @delivery_mode = find_and_check(:delivery_mode, params[:id])
    if request.post?
      redirect_to_back if @delivery_mode.update_attributes(params[:delivery_mode])
    end
    @title = {:value=>@delivery_mode.name}
    render_form
  end
   
  def delivery_mode_delete
    @delivery_mode = find_and_check(:delivery_mode, params[:id])
    if request.post? or request.delete?
      redirect_to_back if @delivery_mode.destroy
    end
  end

  dyta(:sale_order_invoices, :model=>:invoices, :conditions=>{:company_id=>['@current_company.id'],:sale_order_id=>['session[:current_sale_order]']}, :children=>:lines) do |t|
    t.column :number, :children=>:designation
    # t.column :address, :through=>:contact, :children=>:product_name
    t.column :created_on, :children=>false
    t.column :amount
    t.column :amount_with_taxes
    t.action :invoice_print
  end
  
#   def sales_invoices
#     @sale_order = find_and_check(:sale_order, params[:id])
#     session[:current_sale_order] = @sale_order.id
#     # @rest_to_invoice = @sale_order.deliveries.detect{|x| x.invoice_id.nil?}
#     @can_invoice = !@sale_order.lines.detect{|x| x.undelivered_quantity > 0}
#     @can_invoice = false if @sale_order.invoiced
#     if request.post?
#      #  ActiveRecord::Base.transaction do
# #         deliveries = params[:deliveries_to_invoice].select{|k,v| v[:invoiceable].to_i==1}.collect do |id, attributes|
# #           delivery = Delivery.find_by_id_and_company_id(id.to_i,@current_company.id)
# #           delivery.stocks_moves_create if delivery and !delivery.moved_on.nil?
# #           delivery
# #         end
# #         raise ActiveRecord::Rollback unless @current_company.invoice(deliveries)
#      # end
#       # @current_company.invoice(@sale_order)
#       ActiveRecord::Base.transaction do  
#         raise ActiveRecord::Rollback unless @sale_order.invoice
#       end
#       redirect_to :action=>:sale_order_summary, :id=>@sale_order.id
#     end
#   end
  
  
  dyta(:embankments, :conditions=>{:company_id=>['@current_company.id']}, :default_order=>"created_at DESC") do |t|
    t.column :amount, :url=>{:action=>:embankment}
    t.column :payments_count
    t.column :name, :through=>:bank_account
    t.column :label, :through=>:embanker
    t.column :created_on
    t.action :embankment_print
    t.action :embankment_update, :if=>'RECORD.locked == false'
    t.action :embankment_delete, :method=>:delete, :confirm=>:are_you_sure, :if=>'RECORD.locked == false'
  end

#  dyli(:bank_account, :attributes => [:name], :conditions => {:company_id=>['@current_company.id'], :entity_id=>['@current_company.entity_id']})

  dyta(:embankment_payments, :model=>:payments, :conditions=>{:company_id=>['@current_company.id'], :embankment_id=>['session[:embankment_id]']}, :per_page=>1000, :export=>false) do |t|
    t.column :full_name, :through=>:entity
    t.column :bank
    t.column :account_number
    t.column :check_number
    t.column :paid_on
    t.column :amount
  end

  dyta(:embankable_payments, :model=>:payments, :conditions=>["company_id=? AND (embankment_id=? OR (mode_id=? AND embankment_id IS NULL))", ['@current_company.id'], ['session[:embankment_id]'], ['session[:payment_mode_id]']], :per_page=>100, :default_order=>"created_at DESC", :line_class=>"((RECORD.to_bank_on||Date.yesterday)>Date.today ? 'critic' : '')") do |t|
    t.column :full_name, :through=>:entity
    t.column :bank
    t.column :account_number
    t.column :check_number
    t.column :paid_on
    t.column :label, :through=>:embanker
    t.column :amount
    t.check :to_embank, :value=>'(session[:embankment_id].nil? ? (RECORD.embanker.nil? or RECORD.embanker_id==@current_user.id) : (RECORD.embankment_id==session[:embankment_id]))'
  end


  def embankments
  end

  def embankment
    @embankment = find_and_check(:embankment, params[:id])
    session[:embankment_id] = @embankment.id
    @title = {:date=>@embankment.created_on}
  end
  
  def embankment_print
    return unless embankment = find_and_check(:embankment, params[:id])
    print(embankment, :filename=>tc('embankment', :creation=>::I18n.localize(embankment.created_on)))
#     if @current_company.default_contact.nil? || @embankment.bank_account.address.nil?
#       entity = @current_company.default_contact.nil? ? @current_company.name : @embankment.bank_account.name
#       flash[:warning]=tc(:no_contacts, :name=>entity)
#       redirect_to_back
#     else
#       @payments = @current_company.payments.find_all_by_embankment_id(@embankment.id)
#       @lines = []
#       @lines =  @current_company.default_contact.address.split(",").collect{ |x| x.strip}
#       @lines <<  @current_company.default_contact.phone if !@current_company.default_contact.phone.nil?
#       #raise Exception.new @embankment.bank_account.bank_name.inspect
#       @account_address = @embankment.bank_account.address.split("\n")
#       print(@embankment, :archive=>false, :filename=>tc('embankment')+" "+@embankment.created_on.to_s)
#     end
  end

  def embankment_create
    mode = PaymentMode.find_by_id_and_company_id(params[:mode_id], @current_company.id)
    if mode.nil?
      flash[:warning] = tc('messages.need_payment_mode_to_create_embankment')
      redirect_to :action=>:embankments
      return
    end
    if mode.embankable_payments.size <= 0
      flash[:warning]=tc(:no_check_to_embank)
      redirect_to :action=>:embankments
      return
    end
    session[:embankment_id] = nil
    session[:payment_mode_id] = mode.id
    if request.post?
      @embankment = Embankment.new(params[:embankment])
      # @embankment.mode_id = @current_company.payment_modes.find(:first, :conditions=>{:mode=>"check"}).id if @current_company.payment_modes.find_all_by_mode("check").size == 1
      @embankment.mode_id = mode.id 
      @embankment.company_id = @current_company.id 
      if @embankment.save
        payments = params[:embankable_payments].collect{|id, attrs| (attrs[:to_embank].to_i==1 ? id.to_i : nil)}.compact
        Payment.update_all({:embankment_id=>@embankment.id}, ["company_id=? AND id IN (?)", @current_company.id, payments])
        @embankment.refresh
        redirect_to :action=>:embankments
      end
      # redirect_to :action=>:embankment_payment_create, :id=>@embankment.id if @embankment.save
    else
      @embankment = Embankment.new(:created_on=>Date.today, :mode_id=>mode.id, :embanker_id=>@current_user.id)
    end
    @title = {:mode=>mode.name}
    render_form
  end


  def embankment_update
    return unless @embankment = find_and_check(:embankment, params[:id])
    session[:embankment_id] = @embankment.id
    session[:payment_mode_id] = @embankment.mode_id
    if request.post?
      if @embankment.update_attributes(params[:embankment])
        ActiveRecord::Base.transaction do
          payments = params[:embankable_payments].collect{|id, attrs| (attrs[:to_embank].to_i==1 ? id.to_i : nil)}.compact
          Payment.update_all({:embankment_id=>nil}, ["company_id=? AND embankment_id=?", @current_company.id, @embankment.id])
          Payment.update_all({:embankment_id=>@embankment.id}, ["company_id=? AND id IN (?)", @current_company.id, payments])
        end
        @embankment.refresh
        redirect_to :action=>:embankments 
      end
    end
    @title = {:date=>@embankment.created_on}
    render_form
  end
  
#   def embankment_update
#     @embankment = find_and_check(:embankment, params[:id])
#     if request.post?
#       redirect_to :action=>:embankment_payment_update, :id=>@embankment.id if @embankment.update_attributes(params[:embankment])
#     end
#     @title = {:date=>@embankment.created_on}
#     render_form
#   end

  def embankment_delete
    @embankment = find_and_check(:embankment, params[:id])
    if request.post? or request.delete?
      redirect_to_current if @embankment.destroy
    end
  end

#   def embankment_payment_create
#     @embankment = find_and_check(:embankment, params[:id])
#     @checks = @current_company.checks_to_embank(@embankment.mode_id)
#  #   raise Exception.new @checks[0].inspect
#     if request.post?
#       payments = params[:check].collect{|x| Payment.find_by_id_and_company_id(x[0],@current_company.id)} if !params[:check].nil?
#       if !payments.nil?
#         for payment in payments
#           payment.update_attributes!(:embankment_id=>@embankment.id)
#         end
#       end
#       redirect_to :action=>:embankments
#     end
#   end

#   def embankment_payment_update
#     @embankment = find_and_check(:embankment, params[:id])
#     @checks = @current_company.checks_to_embank_on_update(@embankment)
#     if request.post?
#       if params[:check].nil?
#         flash[:warning]=tc(:choose_one_check_at_less)
#         redirect_to_current
#       else

#         for check in @embankment.checks
#           if params[:check][check.id.to_s].nil?
#             check.update_attributes(:embankment_id=>nil) 
#             @embankment.save
#           end
#         end
#         payments = params[:check].collect{|x| Payment.find_by_id_and_company_id(x[0],@current_company.id)} if !params[:check].nil?
#         for payment in payments
#           payment.update_attributes(:embankment_id=>@embankment.id) if payment.embankment_id.nil?
#         end
#         redirect_to :action=>:embankments
#       end
      
#     end
    
#   end
  
  dyta(:payment_modes, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :label, :through=>:account
    t.action :payment_mode_update
    t.action :payment_mode_delete, :method=>:delete, :confirm=>:are_you_sure
  end
  
  dyli(:account, :label, :conditions =>{:company_id=>['@current_company.id']})

  def payment_modes
  end

  def payment_mode_create
    if request.post?
      @payment_mode = PaymentMode.new(params[:payment_mode])
      @payment_mode.company_id = @current_company.id
      redirect_to_back if @payment_mode.save
    else
      @payment_mode = PaymentMode.new(:mode=>"other")
    end
    render_form
  end

  def payment_mode_update
    @payment_mode = find_and_check(:payment_modes, params[:id])
    if request.post?
      redirect_to_back if @payment_mode.update_attributes(params[:payment_mode])
    end
    render_form
  end

  def payment_mode_delete
    @payment_mode = find_and_check(:payment_modes, params[:id])
    if request.post? or request.delete?
      redirect_to_back if @payment_mode.destroy
    end
  end

  dyta(:payment_parts, :conditions=>{:company_id=>['@current_company.id'], :order_id=>['session[:current_sale_order]']}) do |t|
    t.column :amount, :through=>:payment, :label=>tc('payment_amount')
    t.column :amount
    t.column :payment_way
    t.column :scheduled, :through=>:payment, :datatype=>:boolean, :label=>tc('scheduled')
    t.column :downpayment
    #t.column :paid_on, :through=>:payment, :label=>tc('paid_on'), :datatype=>:date
    t.column :to_bank_on, :through=>:payment, :label=>tc('to_bank_on')
    t.action :payment_update
    t.action :payment_delete, :method=>:delete, :confirm=>:are_you_sure
  end

  
  def sale_order_summary
    @sale_order = find_and_check(:sale_orders, params[:id]||session[:current_sale_order])
    @payments = @sale_order.payment_parts
    @invoices = @sale_order.invoices
    @invoices_sum = 0
    @invoices.each {|i| @invoices_sum += i.amount_with_taxes}
    @payments_sum = 0 
    @payments.each {|p| @payments_sum += p.amount}
    session[:current_sale_order] = @sale_order.id
    if request.post?
      # @sale_order.update_attribute(:state, 'F') if @sale_order.state == 'R'
      #redirect_to :action=>:sale_order_summary, :id=>@sale_order.id
    end
  end
 
  dyta(:waiting_payments, :model=>:payments, :conditions=>{:company_id=>['@current_company.id'], :received=>false}) do |t|
    t.column :full_name, :through=>:entity, :url=>{:controller=>:relations, :action=>:entity}
    t.column :amount
    t.column :name, :through=>:mode
    t.column :to_bank_on
  end

  def payments
    @payments_count = @current_company.payments.find(:all, :conditions=>{:received=>false}).size
  end

  def payment_create
    @sale_order = find_and_check(:sale_orders, session[:current_sale_order])
    if @sale_order.unpaid_amount <= 0 and @sale_order.invoices.size > 0
      flash[:notice]=tc(:error_sale_order_already_paid)
      redirect_to :action=>:sale_order_summary, :id=>@sale_order.id
      return
    end
    @modes = ["new", "existing_part"]
    @payments = @sale_order.client.usable_payments
    if request.post?
     # raise Exception.new params[:downpayment][:check].inspect
      if params[:price] and params[:price][:mode] == "existing_part"
        @payment = find_and_check(:payment, params[:pay][:part])
      else
        @payment = Payment.new(params[:payment])
        @payment.company_id = @current_company.id
        @payment.entity_id = @sale_order.client_id
        @payment.save
      end
      if @payment.errors.size <= 0
        if @payment.pay(@sale_order, params[:downpayment][:check] )
          redirect_to :action=>:sale_order_summary, :id=>@sale_order.id
        end
      end
    else
      last_payment = @sale_order.client.payments.find(:first, :order=>"paid_on desc")
      #raise Exception.new last_payment.inspect
      has_invoices = (@sale_order.invoices.size>0)
      @payment = Payment.new(:paid_on=>Date.today, :to_bank_on=>Date.today, :amount=>@sale_order.unpaid_amount(has_invoices), :embanker_id=>@current_user.id, :bank=>last_payment.nil? ? "" : last_payment.bank, :account_number=>last_payment.nil? ? "" : last_payment.account_number)
    end
    @title = {:value=>@sale_order.number}
    render_form
  end
  

  def payment_update
    @sale_order   = find_and_check(:sale_order, session[:current_sale_order])
    return if (payment_part = find_and_check(:payment_part, params[:id])).nil?
    @payment = payment_part.payment
    if request.post?
      if @payment.update_attributes(params[:payment])
        if @payment.pay(@sale_order,  params[:downpayment][:check])
          redirect_to :action=>:sale_order_summary, :id=>@sale_order.id 
        end
      end
    end
    render_form 
  end

  def payment_delete
    @sale_order  = find_and_check(:sale_order, session[:current_sale_order])
    @payment_part = find_and_check(:payment_part, params[:id])
    if request.post? or request.delete?
      @payment_part.destroy
      redirect_to :action=>:sale_order_summary, :id=>@sale_order.id
    end
  end
  

  dyta(:shelves, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :comment
    t.column :catalog_name
    t.column :catalog_description
    t.column :name, :through=>:parent
    t.action :shelf_update
    t.action :shelf_delete, :method=>:delete, :confirm=>:are_you_sure
  end

  def shelves
   # shelves_list params
  end

  def shelf
    return unless @shelf = find_and_check(:shelf, params[:id])
    @title = {:value=>@shelf.name}
  end

  def shelf_create
    if request.post? 
      @shelf = Shelf.new(params[:shelf])
      @shelf.company_id = @current_company.id
      redirect_to_back if @shelf.save
    else
      @shelf = Shelf.new
    end
    render_form
  end

  def shelf_update
    @shelf = find_and_check(:shelf, params[:id])
    if request.post?
      params[:shelf][:company_id] = @current_company.id
      redirect_to_back if @shelf.update_attributes(params[:shelf])
    end
    render_form(:label=>@shelf.name)
  end

  def shelf_delete
    @shelf = find_and_check(:shelf, params[:id])
    if request.post? or request.delete?
      redirect_to :back if @shelf.destroy
    end
  end


  dyta(:stock_locations, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :name, :through=>:establishment
    t.column :name, :through=>:parent
    t.column :reservoir, :label=>tc(:reservoir)
    t.action :stock_location, :image=>:show
    #t.action :stock_location_update, :mode=>:reservoir, :if=>'RECORD.reservoir == true'
    t.action :stock_location_update
    #t.action :stock_location_delete, :method=>:delete, :confirm=>:are_you_sure
  end

  dyta(:stock_moves, :conditions=>{:company_id=>['@current_company.id'], :location_id=>['session[:current_stock_location_id]']}) do |t|
    t.column :name
    t.column :planned_on
    t.column :moved_on
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :name, :through=>:product
    t.column :virtual
    t.action :stock_move_update, :if=>'RECORD.generated != true'
    t.action :stock_move_delete, :method=>:delete, :confirm=>:are_you_sure,:if=>'RECORD.generated != true' 
  end
  
  def stock_locations
    unless @current_company.stock_locations.size>0
      flash[:message] = tc('messages.need_stock_location_to_record_stock_moves')
      redirect_to :action=>:stock_location_create
      return
    end
  end

  def stock_location
    @stock_location = find_and_check(:stock_location, params[:id])
    session[:current_stock_location_id] = @stock_location.id
    @title = {:value=>@stock_location.name}
  end

  def stock_location_create
    @mode = (params[:mode]||session[:location_type]||:original).to_sym
    session[:location_type] = @mode
    if request.post? 
      @stock_location = StockLocation.new(params[:stock_location])
      @stock_location.company_id = @current_company.id
      if @stock_location.save
        if session[:history][1].to_s.include? "stocks" 
          redirect_to :action=>:stock_location, :id=>@stock_location.id
        else
          redirect_to_back
        end
      end
    else
      @stock_location = StockLocation.new
    end
    render_form
  end

  def stock_location_update
    @stock_location = find_and_check(:stock_location, params[:id])
    @mode = :reservoir if @stock_location.reservoir
    if request.post?
      if @stock_location.update_attributes(params[:stock_location])
        redirect_to :action=>:stock_location, :id=>@stock_location.id
      end
    end
    render_form(:label=>@stock_location.name)
  end

  def stock_location_delete
    @stock_location = find_and_check(:stock_location, params[:id])
    if request.post? or request.delete?
      redirect_to :back if @stock_location.destroy
    end
  end

  def stock_move_create
    @stock_location = StockLocation.find_by_id session[:current_stock_location_id]
    if request.post? 
      @stock_move = StockMove.new(params[:stock_move])
      @stock_move.company_id = @current_company.id
      # @stock_move.virtual = true
      # @stock_move.input = true
      #if @stock_move.save
        # @stock_move.change_quantity
      redirect_to :action =>:stock_location, :id=>@stock_move.location_id if @stock_move.save
      #end
    else
      @stock_move = StockMove.new
      @stock_move.planned_on = Date.today
    end
    render_form
  end

  def stock_move_update
    @stock_move = find_and_check(:stock_move, params[:id])
    if request.post?
      redirect_to :action=>:stock_location, :id=>@stock_move.location_id if @stock_move.update_attributes(params[:stock_move])
    end
    @title = {:value=>@stock_move.name}
    render_form
  end

  def stock_move_delete 
    @stock_move = find_and_check(:stock_move, params[:id])
    if request.post? or request.delete?
      redirect_to :back if @stock_move.destroy
    end
  end

  dyta(:subscription_natures, :conditions=>{:company_id=>['@current_company.id']}, :children=>:products) do |t|
    t.column :name
    t.column :nature_label, :children=>false
    t.column :actual_number, :children=>false
    t.column :reduction_rate, :children=>false
    t.action :subscription_nature_increment, :method=>:post, :if=>"RECORD.nature=='quantity'"
    t.action :subscription_nature_decrement, :method=>:post, :if=>"RECORD.nature=='quantity'"
    t.action :subscription_nature
    t.action :subscription_nature_update
  end

  def subscription_natures
  end


  def subscription_nature
    @subscription_nature = find_and_check(:subscription_nature, params[:id])
    session[:subscription_nature] = @subscription_nature
    redirect_to :action=>:subscriptions, :nature=>@subscription_nature.id
  end


  def subscription_nature_create
    @subscription_nature = SubscriptionNature.new
    @subscription_nature.nature = SubscriptionNature.natures.first[1]
    if request.post?
      @subscription_nature = SubscriptionNature.new(params[:subscription_nature])
      @subscription_nature.company_id = @current_company.id
      redirect_to_back if @subscription_nature.save
    end
    render_form
  end

  def subscription_nature_update
    @subscription_nature = find_and_check(:subscription_nature, params[:id])
    if request.post?
      redirect_to_back if @subscription_nature.update_attributes(params[:subscription_nature])
    end
    @title = {:value=>@subscription_nature.name}
    render_form
  end

  def subscription_nature_increment
    return unless @subscription_nature = find_and_check(:subscription_nature, params[:id])
    if request.post?
      @subscription_nature.increment!(:actual_number)
      flash[:notice]=tc('new_actual_number', :value=>@subscription_nature.actual_number)
      redirect_to_current
    end
  end

  def subscription_nature_decrement
    return unless @subscription_nature = find_and_check(:subscription_nature, params[:id])
    if request.post?
      @subscription_nature.decrement!(:actual_number)
      flash[:notice]=tc('new_actual_number', :value=>@subscription_nature.actual_number)
      redirect_to_current
    end
  end

  def self.subscriptions_conditions(options={})
    code = ""
    code += "conditions = [ \" company_id = ? AND COALESCE(sale_order_id,0) NOT IN (SELECT id from sale_orders WHERE company_id = ? and state = 'P') \" , @current_company.id, @current_company.id] \n"
    code += "if session[:subscriptions][:nature].is_a? Hash \n"
    code += "conditions[0] += \" AND nature_id = ?\" \n "
    code += "conditions << session[:subscriptions][:nature]['id'].to_i \n"
    code += "end \n"
    code += "if session[:subscriptions][:nature]['nature'] == 'quantity' \n"
    code += "conditions[0] += \" AND ? BETWEEN first_number AND last_number\" \n"
    code += "elsif session[:subscriptions][:nature]['nature'] == 'period' \n"
    code += "conditions[0] += \" AND ? BETWEEN started_on AND stopped_on\" \n"
    code += "end \n"
    code += "conditions << session[:subscriptions][:instant] \n"
    code += "conditions \n"
    code
  end

  dyta(:subscriptions, :conditions=>subscriptions_conditions, :export=>false) do |t|
    t.column :full_name, :through=>:entity, :url=>{:action=>:entity, :controller=>:relations}
#    t.column :line_2, :through=>:contact, :label=>"Dest-Serv"
#    t.column :line_3, :through=>:contact, :label=>"Bat./Rés."
#    t.column :line_4_number, :through=>:contact, :label=>"N° voie"
#    t.column :line_4_street, :through=>:contact, :label=>"Libelle voie"
#    t.column :line_5, :through=>:contact, :label=>"Lieu dit"
#    t.column :line_6_code, :through=>:contact, :label=>"Code postal"
#    t.column :line_6_city, :through=>:contact, :label=>"Ville"
    t.column :name, :through=>:product
    #t.column :started_on
    #t.column :finished_on
    #t.column :first_number
    #t.column :last_number
    t.column :start
    t.column :finish
  end

#   def subscription_options_display
    
#     @subscription_nature = find_and_check(:subscription_nature, params[:subscription_nature_id])
#     # raise Exception.new params.inspect+"kkkkkkkkkkkkkkkkkkkk"+@subscription_nature.inspect
    
#   end

  def subscription_options
    @subscription_nature = find_and_check(:subscription_nature, params[:nature])
    render :partial=>'subscription_options'
  end


  def subscriptions
    if @current_company.subscription_natures.size == 0
      flash[:warning]=tc(:need_to_create_subscription_nature)
      redirect_to :action=>:subscription_natures
      return
    end
    if params[:nature]
      return unless @subscription_nature = find_and_check(:subscription_nature, params[:nature])
    end
    @subscription_nature ||= @current_company.subscription_natures.first
    session[:subscriptions] ||= {}
    session[:subscriptions][:nature]  = @subscription_nature.attributes
    instant = (@subscription_nature.period? ? params[:instant].to_date : params[:instant]) rescue nil 
    session[:subscriptions][:instant] = instant||@subscription_nature.now
  end

  # dyli(:subscription_contacts,  [:address] ,:model=>:contact, :conditions=>{:entity_id=>['session[:current_entity]'], :active=>true, :company_id=>['@current_company.id']})
  dyli(:subscription_contacts,  ['entities.full_name', :address] ,:model=>:contact, :joins=>"JOIN entities ON (entity_id=entities.id)", :conditions=>{:active=>true, :company_id=>['@current_company.id']})
  
  def subscription_create
    if request.post?
      @subscription = Subscription.new(params[:subscription])
      @subscription.company_id = @current_company.id
      redirect_to_back if @subscription.save
    else
      @subscription = Subscription.new(:entity_id=>params[:entity_id])
    end
    @subscription_nature = @subscription.nature
    render_form
  end
  

  def subscription_update
    return unless @subscription = find_and_check(:subscription, params[:id])
    if request.post?
      redirect_to_back if @subscription.update_attributes!(params[:subscription])
    end
    @title = {:value=>@subscription.nature.name, :start=>@subscription.start, :finish=>@subscription.finish}
    render_form
  end

  def subscription_delete
    return unless @subscription = find_and_check(:subscription, params[:id])
    if request.post? or request.delete?
      redirect_to_current if @subscription.destroy
    end    
  end
  
  def subscriptions_period    
    @subscription = Subscription.new(:nature=>SubscriptionNature.find_by_company_id_and_id(@current_company.id, params[:subscription_nature_id].to_i))
    render :partial=>'subscriptions_period_form'
  end



  # TO DELETE
#   def subscriptions2()
#     if @current_company.subscription_natures.size == 0
#       flash[:warning]=tc(:need_to_create_subscription_nature)
#       redirect_to :action=>:subscription_natures
#     else 
#       session[:sub_is_date] = 0 
#       if not params[:nature].nil?
#         @subscription_nature = find_and_check(:subscription_nature, params[:nature])
#         session[:subscription_instant] = @subscription_nature.nature == "quantity" ? @subscription_nature.actual_number : Date.today
#         session[:sub_is_date] = @subscription_nature.nature == "quantity" ? 2 : 1
#       else
#         @subscription_nature = session[:subscription_nature]||@current_company.subscription_natures.find(:first)
#       end
#       session[:subscription_nature] = @subscription_nature
#     end
#     if request.post?
#       @subscription_nature = find_and_check(:subscription_nature, params[:subscription_nature][:id])
#       if @subscription_nature
#         session[:subscription] = 
#         if @subscription_nature.nature == "quantity"
#           session[:subscription_instant]= params[:subscription][:value].to_i > 0 ? params[:subscription][:value].to_i : 0
#           session[:sub_is_date] = 2
#         elsif @subscription_nature.nature == "period" and !params[:subscription][:value].nil?
#           begin
#             params_to_date = params[:subscription][:value].to_date
#             session[:subscription_instant] = params_to_date
#           rescue
#             session[:subscription_instant] = Date.today
#             flash[:warning]=tc(:unvalid_date)
#           end
#           session[:sub_is_date] = 1
#         end
#       end
#     end
#   end
  
  
  
  dyta :undelivered_sales, :model=>:deliveries, :children=>:lines, :conditions=>{:company_id=>['@current_company.id'], :moved_on=>nil}, :line_class=>'RECORD.moment.to_s' do |t| # ,:order=>{'sort'=>"planned_on", 'dir'=>"ASC"}
    t.column :label, :children=>:product_name
    t.column :planned_on, :children=>false
    t.column :quantity, :datatype=>:decimal
    t.column :amount
    t.column :amount_with_taxes
    t.check :delivered, :value=>'RECORD.planned_on<=Date.today'
  end


  def undelivered_sales
    @deliveries = Delivery.find(:all,:conditions=>{:company_id=>@current_company.id, :moved_on=>nil},:order=>"planned_on ASC")  
    if request.post?
      for id, values in params[:undelivered_sales]
        #raise Exception.new params.inspect+id.inspect+values.inspect
        delivery = Delivery.find_by_id_and_company_id(id, @current_company.id)
        delivery.ship if delivery and values[:delivered].to_i == 1
      end
      redirect_to :action=>:undelivered_sales
    end
  end
  

  dyta(:unexecuted_transfers, :model=>:stock_transfers, :conditions=>{:company_id=>['@current_company.id'], :moved_on=>nil}, :order=>{'sort'=>"planned_on", 'dir'=>"ASC"}) do |t| 
    t.column :text_nature
    t.column :name, :through=>:product
    t.column :quantity, :datatype=>:decimal
    t.column :name, :through=>:location
    t.column :name, :through=>:second_location
    t.column :planned_on, :children=>false
    t.check :executed, :value=>'RECORD.planned_on<=Date.today'
  end
  
  def unexecuted_transfers
    @stock_transfers = @current_company.stock_transfers.find(:all, :conditions=>{:moved_on=>nil}, :order=>"planned_on ASC")
    if request.post?
  #     #raise Exception.new params.inspect
#       stock_transfers = params[:stock_transfer].collect{|x| StockTransfer.find_by_id_and_company_id(x[0], @current_company.id)} if !params[:stock_transfer].nil?
#       if !stock_transfers.nil?
#         for stock_transfer in stock_transfers
#           stock_transfer.execute_transfer
#         end
#      end
      for id, values in params[:unexecuted_transfers]
        transfer = StockTransfer.find_by_id_and_company_id(id, @current_company.id)
        transfer.execute_transfer if transfer and values[:executed].to_i == 1
      end
      redirect_to :action=>:unexecuted_transfers
    end
  end
  
  dyta(:unreceived_purchases, :model=>:purchase_orders, :children=>:lines, :conditions=>{:company_id=>['@current_company.id'], :moved_on=>nil}, :order=>{'sort'=>"planned_on", 'dir'=>"ASC"}) do |t| 
    t.column :label, :children=>:product_name
    t.column :planned_on, :children=>false
    t.column :quantity, :datatype=>:decimal
    t.column :amount
    t.column :amount_with_taxes
    t.check :received, :value=>'RECORD.planned_on<=Date.today'
  end


  def unreceived_purchases
    @purchase_orders = PurchaseOrder.find(:all, :conditions=>{:company_id=>@current_company.id, :moved_on=>nil}, :order=>"planned_on ASC")
    if request.post?
      #    purchases = params[:purchase].collect{|x| PurchaseOrder.find_by_id_and_company_id(x[0],@current_company.id)} if !params[:purchase].nil?
      #       if !purchases.nil?
      #         for purchase in purchases
      #           purchase.real_stocks_moves_create
      #         end
      #      end
      for id, values in params[:unreceived_purchases]
        purchase = PurchaseOrder.find_by_id_and_company_id(id, @current_company.id)
        purchase.real_stocks_moves_create if purchase and values[:received].to_i == 1
      end
      redirect_to :action=>:unreceived_purchases
    end
  end

 dyta(:unvalidated_embankments, :model=>:embankments, :conditions=>{:locked=>false, :company_id=>['@current_company.id']}) do |t|
    t.column :created_on
    t.column :amount
    t.column :payments_number
    t.column :name, :through=>:bank_account
    t.check :validated, :value=>'RECORD.created_on<=Date.today-(15)'
  end

  def unvalidated_embankments
    @embankments = @current_company.embankments_to_lock
    if request.post?
      for id, values in params[:unvalidated_embankments]
        embankment = Embankment.find_by_id_and_company_id(id, @current_company.id)
        embankment.update_attributes!(:locked=>true) if embankment and values[:validated].to_i == 1
      end
      redirect_to :action=>:unvalidated_embankments
    end
  end
  
  def self.stocks_conditions(options={})
    code = ""
    code += " conditions = {} \n "
    code += "conditions[:company_id] = @current_company.id \n"
    code += " conditions[:location_id] = session[:location_id] if !session[:location_id].nil? \n "
    code += " conditions \n "
    code
  end

  dyta(:product_stocks, :conditions=>stocks_conditions, :line_class=>'RECORD.state') do |t|
    t.column :name, :through=>:product,:url=>{:action=>:product}
    t.column :weight, :through=>:product, :label=>"Poids"
    t.column :quantity_max
    t.column :quantity_min
    t.column :critic_quantity_min
    t.column :current_virtual_quantity
    t.column :current_real_quantity
  end

  dyta(:critic_product_stocks, :model=>:product_stocks, :conditions=>['company_id = ? AND current_virtual_quantity <= critic_quantity_min', ['@current_company.id']] , :line_class=>'RECORD.state') do |t|
    t.column :name, :through=>:product,:url=>{:action=>:product}
    t.column :name, :through=>:location, :label=>"Lieu de stockage"
    t.column :quantity_max
    t.column :quantity_min
    t.column :critic_quantity_min
    t.column :current_virtual_quantity
    t.column :current_real_quantity
  end


  dyta(:uniq_critic_product_stocks, :model=>:product_stocks, :conditions=>['company_id = ? AND current_virtual_quantity <= critic_quantity_min  AND product_id = ?', ['@current_company.id'], ['session[:product_id]']] , :line_class=>'RECORD.state') do |t|
    t.column :name, :through=>:product,:url=>{:action=>:product}
    t.column :name, :through=>:location, :label=>"Lieu de stockage"
    t.column :quantity_max
    t.column :quantity_min
    t.column :critic_quantity_min
    t.column :current_virtual_quantity
    t.column :current_real_quantity
  end

  def stocks
    @stock_locations = StockLocation.find_all_by_company_id(@current_company.id)
    if @stock_locations.size == 0
      flash[:warning]=tc('no_stock_location')
      redirect_to :action=>:stock_location_create
    else
      if request.post?
        session[:location_id] = params[:product_stock][:location_id]
      end
      @product_stock = ProductStock.new(:location_id=>session[:location_id]||StockLocation.find(:first, :conditions=>{:company_id=>@current_company.id} ).id)
    end
  end

  dyta(:stock_transfers, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :text_nature
    t.column :name, :through=>:product
    t.column :quantity
    t.column :name, :through=>:location
    t.column :name, :through=>:second_location
    t.column :planned_on
    t.column :moved_on
    t.action :stock_transfer_update
    t.action :stock_transfer_delete, :method=>:delete, :confirm=>:are_you_sure
  end

  def stock_transfers
  end




  def stock_transfer_create
    @stock_transfer = StockTransfer.new(:nature=>"transfer", :planned_on=>Date.today)
    if request.post?
      @stock_transfer = StockTransfer.new(params[:stock_transfer])
      @stock_transfer.company_id = @current_company.id
      redirect_to_back if @stock_transfer.save
    end
    render_form
  end

  def stock_transfer_update
    @stock_transfer = find_and_check(:stock_transfer, params[:id])
    if request.post?
      #raise Exception.new params.inspect
      redirect_to_back if @stock_transfer.update_attributes!(params[:stock_transfer])
    end
    render_form
  end
  
  def stock_transfer_delete
    @stock_transfer = find_and_check(:stock_transfer, params[:id])
    if request.post? or request.delete?
      redirect_to_back if @stock_transfer.destroy
    end
  end

  dyta(:transports, :children=>:deliveries, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :created_on, :children=>:planned_on
    t.column :transport_on, :children=>false
    t.column :full_name, :through=>:transporter, :children=>:contact_address
    t.column :weight
    t.action :transport_print
    t.action :transport_update
    t.action :transport_delete, :method=>:post, :confirm=>:are_you_sure
  end

  dyta(:transport_deliveries, :model=>:deliveries, :children=>:lines, :conditions=>{:company_id=>['@current_company.id'], :transport_id=>['session[:current_transport]']}) do |t|
    t.column :address, :through=>:contact, :children=>:product_name
    t.column :planned_on, :children=>false
    t.column :moved_on, :children=>false
    t.column :number, :through=>:invoice, :url=>{:action=>:invoice}, :children=>false
    t.column :quantity
    t.column :amount
    t.column :amount_with_taxes
    t.column :weight, :children=>false
    t.action :transport_delivery_delete, :method=>:post, :confirm=>:are_you_sure_to_delete_delivery
  end
  
  def transports
  end
  
  def transport_create
    @transport = Transport.new(:transport_on=>Date.today)
    @transport.responsible_id = @current_user.employee.id if !@current_user.employee.nil?
    session[:current_transport] = 0
    if request.post?
      @transport = Transport.new(params[:transport])
      @transport.company_id = @current_company.id
      redirect_to :action=>:transport_deliveries, :id=>@transport.id if @transport.save
    end
  end

  def transport_update
    return unless @transport = find_and_check(:transports, params[:id])
    session[:current_transport] = @transport.id
    if request.post?
      redirect_to :action=>:transport_update, :id=>@transport.id if @transport.update_attributes(params[:transport])
    end
  end

  dyli(:deliveries, [:planned_on, "contacts.address"], :conditions=>["deliveries.company_id = ? AND transport_id IS NULL", ['@current_company.id']], :joins=>"INNER JOIN contacts ON contacts.id = deliveries.contact_id ")
  
  def transport_deliveries
    return unless @transport = find_and_check(:transports, params[:id]||session[:current_transport])
    session[:current_transport] = @transport.id
    if request.post?
      delivery = find_and_check(:deliveries, params[:delivery][:id].to_i)
      if delivery
        redirect_to :action=>:transport_update, :id=>@transport.id if delivery.update_attributes(:transport_id=>@transport.id) 
      end
    end
  end
  
  def transport_delivery_delete
    return unless @delivery =  find_and_check(:deliveries, params[:id])
    if request.post? or request.delete?
      redirect_to_current if @delivery.update_attributes!(:transport_id=>nil)
    end
  end
  
  def transport_delete
    return unless @transport = find_and_check(:transports, params[:id])
    if request.post? or request.delete?
      redirect_to :action=>:transports if @transport.destroy
    end
  end
 

  def transport_print
    return unless @transport = find_and_check(:transports, params[:id])
    print(@transport, :filename=>tc('transport')+" "+@transport.created_on.to_s)
  end

end
