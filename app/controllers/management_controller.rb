class ManagementController < ApplicationController

  include ActionView::Helpers::FormOptionsHelper

  def index
    #raise Exception.new "jjjjj"+Actions.expire_actions.inspect
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
  end

  dyta(:delays, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :active
    t.column :expression
    t.column :comment
    t.action :delays_display, :image=>:show
    t.action :delays_update, :image=>:update
    t.action :delays_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
  end

  def delays
  end

  def delays_display
    @delay = find_and_check(:delay, params[:id])
    @title = {:value=>@delay.name}
  end

  def delays_create
    if request.post? 
      @delay = Delay.new(params[:delay])
      @delay.company_id = @current_company.id
      redirect_to_back if @delay.save
    else
      @delay = Delay.new
    end
    render_form
  end 

  def delays_update
    @delay = find_and_check(:delay, params[:id])
    if request.post?
      params[:delay][:company_id] = @current_company.id
      redirect_to_back if @delay.update_attributes(params[:delay])
    end
    @title = {:value=>@delay.name}
    render_form
  end

  def delays_delete
    @delay = find_and_check(:delay, params[:id])
    if request.post? or request.delete?
      redirect_to :back if @delay.destroy
    end
  end
  
  def inventories
    
  end
  
  def inventory_consult
    #   srr = @current_company.product_stocks.find_all_by_location_id(1)
    #     for sl in  @current_company.stock_locations
    #       for s in sl.product_stocks
    #         raise Exception.new s.inspect
    #       end
    #  end
    if request.post?
      #raise Exception.new params[:product_stock].inspect
      inventory = Inventory.create!(:company_id=>@current_company.id, :date=>Date.today)
      params[:product_stock].collect{|x| ProductStock.find_by_id_and_company_id(x[0], @current_company.id).reflect_changes(x[1], inventory.id) }
    end
  end
  
  dyta(:all_invoices, :model=>:invoices, :conditions=>"search_conditions(:attributes=>[:number], :key=>session[:invoices_key])", :empty=>true) do |t|
    t.column :number, :url=>{:action=>:invoices_display}
    t.column :full_name, :through=>:client
    t.column :created_on
    t.column :amount
    t.column :amount_with_taxes
    t.column :credit
    t.action :invoices_print
    t.action :invoices_cancel, :if=>'RECORD.credit != true and @current_user.credits'
  end

  def invoices
    @key = params[:key]||session[:invoices_key]
    session[:invoices_key] = @key
    #all_invoices_list({:attributes=>[:number], :key=>@key}.merge(params))
  end

  def invoices_cancel
    @invoice = find_and_check(:invoices, params[:id])
    session[:invoice] = @invoice.id
    @invoice_cancel = Invoice.find_by_origin_id_and_company_id(@invoice.id, @current_company.id)
    if @invoice_cancel.nil?
      @invoice_cancel = Invoice.new(:origin_id=>@invoice.id, :client_id=>@invoice.client_id, :credit=>true, :company_id=>@current_company.id)
      @invoice_cancel_lines = @invoice.lines.collect{|x| InvoiceLine.new(:origin_id=>x.id, :product_id=>x.product_id, :price_id=>x.price_id, :quantity=>0, :company_id=>@current_company.id, :order_line_id=>x.order_line_id)}
    else
      @invoice_cancel_lines = @invoice_cancel.lines
    end
    if request.post?
      ActiveRecord::Base.transaction do
        session[:errors] = []
        saved = @invoice_cancel.save
        if saved
          for cancel_line in @invoice_cancel_lines
            cancel_line.quantity -= (params[:invoice_cancel_line][cancel_line.origin_id.to_s][:quantity].to_f)
            cancel_line.invoice_id = @invoice_cancel.id
            saved = false unless cancel_line.save
          end
        end
        if !saved
          session[:errors] = []
          for line in @invoice_cancel_lines
            session[:errors] << line.errors.full_messages if !line.errors.full_messages.empty?
          end
          redirect_to :action=>:invoices_cancel, :id=>session[:invoice]
          raise ActiveRecord::Rollback
        else
          session[:errors] = []
          redirect_to :action=>:invoices
        end
      end
    end
    @title = {:value=>@invoice.number}
  end
   

  dyta(:invoice_credit_lines, :model=>:invoice_lines, :conditions=>{:company_id=>['@current_company.id'], :invoice_id=>['session[:current_invoice]']}) do |t|
    t.column :name, :through=>:product, :url=>{:action=>:products_display}
    t.column :amount, :through=>:price
    t.column :amount_with_taxes, :through=>:price, :label=>tc('price_amount_with_taxes')
    t.column :quantity
    t.column :amount
    t.column :amount_with_taxes
  end

  dyta(:credits, :model=>:invoices, :conditions=>{:company_id=>['@current_company.id'], :origin_id=>['session[:current_invoice]'] }) do |t|
    t.column :number, :url=>{:action=>:invoices_display}
    t.column :full_name, :through=>:client
    t.column :created_on
    t.column :amount
    t.column :amount_with_taxes
  end


  def invoices_display
    @invoice = find_and_check(:invoice, params[:id])
    session[:current_invoice] = @invoice.id
    @title = {:number=>@invoice.number}
  end
  
  dyta(:prices, :conditions=>:prices_conditions) do |t|
    t.column :name, :through=>:product, :url=>{:action=>:products_display}
    t.column :full_name, :through=>:entity
    t.column :name, :through=>:category, :label=>tc(:category), :url=>{:controller=>:relations, :action=>:entity_categories_display}
    t.column :amount
    t.column :amount_with_taxes
    t.column :default
    t.column :range
    t.action :prices_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
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
  
  def prices_create
    #raise Exception.new params.inspect
    @mode = (params[:mode]||"sales").to_sym 
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
        redirect_to :action=> :products_create
      elsif !params[:product_id].nil?
        @price = Price.new(:product_id=>params[:product_id])
      else
        @price = Price.new(:category_id=>session[:category]||0)
      end
      @price.entity_id = params[:entity_id] if params[:entity_id]
    end
    render_form    
  end
  
  def prices_delete
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
  
  
  dyta(:products, :conditions=>:search_conditions, :empty=>true) do |t|
    t.column :number
    t.column :name, :through=>:shelf, :url=>{:action=>:shelves_display}
    t.column :name, :url=>{:action=>:products_display}
    t.column :code
    t.column :description
    t.column :active
    t.action :products_display, :image=>:show
    t.action :products_update, :image=>:update
    t.action :products_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
  end
  
  dyta(:product_prices, :conditions=>{:company_id=>['@current_company.id'], :product_id=>['session[:product_id]'], :active=>true}, :model=>:prices) do |t|
    t.column :name, :through=>:entity
    t.column :name, :through=>:category, :url=>{:controller=>:relations, :action=>:entity_categories_display}

    t.column :amount
    t.column :amount_with_taxes
    t.column :default
    t.column :range
    t.action :prices_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
  end

  dyta(:product_components, :conditions=>{:company_id=>['@current_company.id'], :product_id=>['session[:product_id]'], :active=>true}) do |t|
    t.column :name
    t.action :product_components_update, :image=>:update
    t.action :product_components_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
  end

  def product_components_create
    @product = find_and_check(:products, session[:product_id])
    if request.post?
      @product_component = ProductComponent.new(params[:product_component])
      @product_component.company_id = @current_company.id
      @product_component.product_id = @product.id
      redirect_to :action=>:products_display, :id=>session[:product_id] if @product_component.save
    else
      @product_component = ProductComponent.new(:quantity=>1.0)
    end
    @title = {:value=>@product.name}
    render_form
  end
  
  def product_components_update
    @product_component = find_and_check(:product_component, params[:id])
    @product = find_and_check(:product, session[:product_id])
    if request.post?
      redirect_to :action=>:products_display, :id=>@product.id if @product_component.update_attributes!(params[:product_component])
    else
      #raise Exception.new @product_component.inspect
    end
    @title = {:product=>@product.name, :component=>@product_component.name}
    render_form
  end

  def product_components_delete
    if request.post?
      @product_component = find_and_check(:product_component, params[:id])
      @product_component.update_attributes!(:active=>false)
      redirect_to :action=>:products_display, :id=>session[:product_id]
    end
  end
  
  def products
    @stock_locations = StockLocation.find_all_by_company_id(@current_company.id)
    if @stock_locations.size < 1
      flash[:warning]=tc('need_stocks_location_to_create_products')
      redirect_to :action=>:stocks_locations_create
    end
    @key = params[:key]||session[:product_key]
    session[:product_key] = @key
   # products_list({:attributes=>[:id, :name, :description, :catalog_name, :catalog_description, :comment], :key=>@key}.merge(params))
  end

  def products_display
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

  def products_create
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
          raise ActiveRecord::Rollback# unless saved  
        end
      end
    else 
      # @product = Product.new(:without_stocks=>true)
      @product = Product.new
      @product.nature = Product.natures.first[1]
      @product.supply_method = Product.supply_methods.first[1]
      @product_stock = ProductStock.new
    end
    render_form
  end
  
  def products_update
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
            save = false unless @product_stock.update_attributes(params[:product_stock])
          end
          @product_stock.errors.each_full do |msg|
            @product.errors.add_to_base(msg)
          end
        end
        raise ActiveRecord::Rollback unless saved  
      end
      redirect_to :action=>:products_display, :id=>@product.id
    end
    @title = {:value=>@product.name}
    render_form()
  end
  
  def products_delete
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
    t.column :full_name, :through=>:supplier, :url=>{:controller=>:relations, :action=>:entities_display}
    t.column :address, :through=>:dest_contact
    t.column :shipped
    t.column :invoiced
    t.column :amount
    t.column :amount_with_taxes
    t.action :purchases_print
  end

  def purchases
  end

  def purchases_print
    @order    = find_and_check(:purchase_order, params[:id])
    @supplier = @order.supplier
    @client   = @current_company.entity
  end

  def purchases_new
    redirect_to :action=>:purchase_orders_create
  end

  def purchase_orders_create
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

  dyta(:purchase_order_lines, :conditions=>{:company_id=>['@current_company.id'], :order_id=>['session[:current_purchase]']}, :empty=>true) do |t|
    t.column :name, :through=>:product, :url=>{:action=>:products_display}
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :amount, :through=>:price
    t.column :amount
    t.column :amount_with_taxes
    t.action :purchase_order_lines_update, :image=>:update, :if=>'RECORD.order.shipped == false'
    t.action :purchase_order_lines_delete,  :image=>:delete, :method=>:post, :confirm=>:are_you_sure, :if=>'RECORD.order.shipped == false'
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


  def purchase_order_lines_create
    @stock_locations = @current_company.stock_locations
    @purchase_order = PurchaseOrder.find_by_id_and_company_id(session[:current_purchase], @current_company.id)
    if @stock_locations.empty?
      flash[:warning]=tc(:need_stock_location_to_create_purchase_order_line)
      redirect_to :action=>:stocks_locations_create
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
  
  def purchase_order_lines_update
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
  
  def purchase_order_lines_delete
    @purchase_order_line = find_and_check(:purchase_order_line, params[:id])
    if request.post? or request.delete?
      redirect_to :back  if @purchase_order_line.destroy
    end
  end
  
  
  dyta(:sale_orders, :conditions=>{:company_id=>['@current_company.id']},:order=>{'sort'=>'created_on','dir'=>'desc'} ) do |t|
    #t.column :number, :url=>{:action=>:sales_details}
    t.column :number, :url=>{:action=>:sales_products}
    t.column :name, :through=>:nature#, :url=>{:action=>:sale_order_natures_display}
    t.column :created_on
    t.column :full_name, :through=>:client, :url=>{:controller=>:relations, :action=>:entities_display}
    t.column :text_state
    t.column :amount
    t.column :amount_with_taxes
    t.action :sale_orders_delete , :method=>:post, :if=>'RECORD.state == "P"'
  end
  
  def sale_orders_delete
    @sale_order = find_and_check(:sale_order, params[:id])
    if request.post? or request.delete?
      if @sale_order.state == 'P'
        @sale_order.destroy
      else
        flash[:warning]=tc('sale_order_can_not_be_deleted')
      end
      redirect_to :action=>:sales
    end
  end
  
  def sales
    #sale_orders_list params
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
    t.column :number, :children=>false, :url=>{:action=>:invoices_display}
    t.column :address, :through=>:contact, :children=>false
    t.column :amount
    t.column :amount_with_taxes
  end
  
  dyta(:payments, :conditions=>{:company_id=>['@current_company.id'], :order_id=>['session[:current_sale_order]']}, :model=>:payment_parts) do |t|
    t.column :amount, :through=>:payment, :label=>"Montant du paiment"
    t.column :amount
    t.column :payment_way
    t.column :paid_on, :through=>:payment, :label=>"Réglé le"
  end
  
  def sales_details
    @sale_order = find_and_check(:sale_order, params[:id])
    session[:current_sale_order] = @sale_order.id
    @title = {:value=>@sale_order.number, :name=>@sale_order.client.full_name} 
  end
  
  dyta(:sale_order_natures, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :active
    t.column :name, :through=>:expiration, :url=>{:action=>:delays_display}, :label=>"Délai d'expiration"
    t.column :name, :through=>:payment_delay, :url=>{:action=>:delays_display}, :label=>"Délai de paiement"
    t.column :downpayment
    t.column :downpayment_minimum
    t.column :downpayment_rate
    t.column :comment
    t.action :sale_order_natures_update, :image=>:update
    t.action :sale_order_natures_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
  end

  def sale_order_natures
  end

  def sale_order_natures_display
    @sale_order_nature = find_and_check(:sale_order_nature, params[:id])
    @title = {:value=>@sale_order_nature.name}
  end

  def sale_order_natures_create
    if request.post? 
      @sale_order_nature = SaleOrderNature.new(params[:sale_order_nature])
      @sale_order_nature.company_id = @current_company.id
      redirect_to_back if @sale_order_nature.save
    else
      @sale_order_nature = SaleOrderNature.new
    end
    render_form
  end

  def sale_order_natures_update
    @sale_order_nature = find_and_check(:sale_order_nature, params[:id])
    if request.post?
      params[:sale_order_nature][:company_id] = @current_company.id
      redirect_to_back if @sale_order_nature.update_attributes(params[:sale_order_nature])
    end
    @title = {:value=>@sale_order_nature.name}
    render_form
  end

  def sale_order_natures_delete
    @sale_order_nature = find_and_check(:sale_order_nature, params[:id])
    if request.post? or request.delete?
      redirect_to :back if @sale_order_nature.destroy
    end
 end



  def sales_contacts
    client_id = params[:client_id]||(params[:sale_order]||{})[:client_id]||session[:current_entity]
    client_id = 0 if client_id.blank?
    session[:current_entity] = client_id
    contacts = Contact.find(:all, :conditions=>{:entity_id=>client_id, :company_id=>@current_company.id, :active=>true})  
    @contacts = contacts.collect{|x| [x.address, x.id]}
    render :text=>options_for_select(@contacts) if request.xhr?
  end

  def sales_new
    redirect_to :action=>:sales_general
  end


  def sales_general
    sales_contacts
    if request.post?
      @sale_order = SaleOrder.new(params[:sale_order])
      @sale_order.company_id = @current_company.id
      @sale_order.number = ''
      @sale_order.state = 'P'
      if @sale_order.save
        redirect_to :action=>:sales_products, :id=>@sale_order.id
      end
    else
      @sale_order = SaleOrder.find_by_id_and_company_id(params[:id], @current_company.id)
      if @sale_order.nil?
        @sale_order = SaleOrder.new 
      end
      session[:current_entity] ||= @current_company.entities.find(:first, :conditions=>{:client=>true})
      @sale_order.client_id = session[:current_entity]
    end
    #    @title = {:client=>@entity.full_name}
  end

#     @sale_order = SaleOrder.new

#     session[:sales] = {}
#     if request.get?
#       session[:sales][:client_id] = params[:client_id]
#     else
#       session[:sales] = params[:sale] if params[:sale].is_a? Hash
#     end

# #    raise Exception.new session.data.inspect

#     if session[:sales][:client_id]
#       client = Entity.find_by_company_id_and_id(session[:sales][:client_id], @current_company.id)
#       session[:sales].delete(:client_id) if client.nil?
#     end
    
#     redirect_to :action=>:sales_general unless session[:sales][:client_id].nil?
#   end

#   def sales_general
#     @step = 2
#     @entity = Entity.find(session[:sales][:client_id])
#     if request.post?
#       @sale_order = SaleOrder.new(params[:sale])
#       @sale_order.company_id = @current_company.id
#       @sale_order.client_id = @entity.id
#       if @sale_order.save
#         redirect_to :action=>:sales_products
#       end
#     else
#       @sale_order = SaleOrder.new
#     end
#     @title = {:client=>@entity.full_name}
#   end

  dyta(:sale_order_lines, :conditions=>{:company_id=>['@current_company.id'], :order_id=>['session[:current_sale_order]']}, :empty=>true) do |t|
    t.column :name, :through=>:product
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :amount, :through=>:price, :label=>tc('price')
    t.column :amount
    t.column :amount_with_taxes
    t.action :sale_order_lines_update, :image=>:update, :if=>'RECORD.order.state == "P"'
    t.action :sale_order_lines_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure, :if=>'RECORD.order.state == "P"'
  end

  def sales_products
    @sale_order = find_and_check(:sale_order, params[:id])
    session[:current_sale_order] = @sale_order.id
    session[:category] = @sale_order.client.category
    @stock_locations = @current_company.stock_locations
    @entity = @sale_order.client
    #sale_order_lines_list params
    #raise Exception.new params.inspect
    if request.post?
      #raise Exception.new params.inspect
      if params[:commit] != "bla"
        if @sale_order.state == 'L'
          flash[:warning]=tc('sale_order_already_ordered')
        else
          @sale_order.confirmed_on = Date.today
          @sale_order.update_attribute(:state, 'L') if @sale_order.state == 'P'
          @sale_order.stocks_moves_create
        end
        redirect_to :action=>:sales_deliveries, :id=>@sale_order.id
      else
        redirect_to :action=>:add_lines, :sale_order_line=>params[:sale_order_line]
      end
    end
    @title = {:client=>@entity.full_name, :sale_order=>@sale_order.number}
  end

  def sales_print
    @sale_order = find_and_check(:sale_order, params[:id])
    if @current_company.default_contact.nil? || @sale_order.client.contacts.size == 0
      entity = @current_company.default_contact.nil? ? @current_company.name : @sale_order.client.full_name
      flash[:warning]=tc(:no_contacts, :name=>entity)
      redirect_to_back
    else
      @lines = []
      @lines =  @current_company.default_contact.address.split(",").collect{ |x| x.strip}
      @lines <<  @current_company.default_contact.phone if !@current_company.default_contact.phone.nil?
      @client_address = @sale_order.contact.address.split(",").collect{ |x| x.strip}
      #raise Exception.new @sale_order.payment_delay.compute(Date.today.to_s)
    end
  end


  def add_lines
    @sale_order_line = @current_company.sale_order_lines.find(:first, :conditions=>{:price_id=>params[:sale_order_line][:price_id], :order_id=>session[:current_sale_order]})
    if @sale_order_line
      @sale_order_line.quantity += params[:sale_order_line][:quantity].to_d
      @sale_order_line.save
    else
      @sale_order_line = SaleOrderLine.new(params[:sale_order_line])
      @sale_order_line.company_id = @current_company.id 
      @sale_order_line.order_id = session[:current_sale_order]
      @sale_order_line.product_id = find_and_check(:prices,params[:sale_order_line][:price_id]).product_id
      @sale_order_line.location_id = @stock_locations[0].id if @stock_locations.size == 1
    end
    redirect_to :action=>:sales_products, :id=>session[:current_sale_order]
    #raise Exception.new @sale_order_line.inspect
  end
  
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
    @product = find_and_check(:products, price.product_id)
    puts @product.inspect
   # raise Exception.new @price.product.inspect
  end

  def subscription_message
    price = find_and_check(:prices, params[:sale_order_line_price_id])
    @product = find_and_check(:products, price.product_id)
  end

  def sale_order_lines_create
    # @delay = Delay.find_by_id(100)
    # raise Exception.new Date.today.inspect+"   "+@delay.expression.inspect+"  "+@delay.compute(Date.today).inspect
    @stock_locations = @current_company.stock_locations
    @sale_order = SaleOrder.find(:first, :conditions=>{:company_id=>@current_company.id, :id=>session[:current_sale_order]})
    @sale_order_line = SaleOrderLine.new(:price_amount=>0.0)
    @subscription = Subscription.new
    #raise Exception.new params.inspect
    if @stock_locations.empty? 
      flash[:warning]=tc(:need_stock_location_to_create_sale_order_line)
      redirect_to :action=>:stocks_locations_create
    elsif @sale_order.state == 'L'
      flash[:warning]=tc(:impossible_to_add_lines)
      redirect_to :action=>:sales_products, :id=>@sale_order.id
    else
      if request.post? 
        #raise Exception.new "jhuhyuhu"+params.inspect
        @sale_order_line = @current_company.sale_order_lines.find(:first, :conditions=>{:price_id=>params[:sale_order_line][:price_id], :order_id=>session[:current_sale_order]})
        if @sale_order_line and params[:sale_order_line][:price_amount].to_d <= 0
          @sale_order_line.quantity += params[:sale_order_line][:quantity].to_d
        else
          @sale_order_line = SaleOrderLine.new(params[:sale_order_line])
          @sale_order_line.company_id = @current_company.id
          @sale_order_line.order_id = session[:current_sale_order]
          @sale_order_line.product_id = find_and_check(:prices,params[:sale_order_line][:price_id]).product_id
          @sale_order_line.location_id = @stock_locations[0].id if @stock_locations.size == 1
        end
        ActiveRecord::Base.transaction do
          saved = @sale_order_line.save
          if saved 
            if @sale_order_line.is_a_subscription
              @subscription = Subscription.new(:sale_order_id=>@sale_order.id, :company_id=>@current_company.id, :product_id=>@sale_order_line.product_id)

              if @sale_order_line.product.subscription_nature.nature == "period"
                if not params[:subscription].nil?    
                  @subscription.started_on = params[:subscription][:started_on]
                  @subscription.finished_on = params[:subscription][:finished_on]
                else ## from quick_line
                  @subscription.started_on = Date.today
                  delay = Delay.new(:expression=>@sale_order_line.product.subscription_period, :name=>"temp")
                  @subscription.finished_on = delay.compute(Date.today)
                end
              elsif @sale_order_line.product.subscription_nature.nature == "quantity"
                if not params[:subscription].nil?
                  @subscription.first_number = params[:subscription][:first_number]
                  @subscription.last_number = params[:subscription][:last_number]
                else  ## from quick_line
                  @subscription.first_number = @sale_order_line.product.subscription_nature.actual_number
                  @subscription.last_number = (@sale_order_line.product.subscription_nature.actual_number + @sale_order_line.product.subscription_quantity)
                end
              end
              if not params[:subscription].nil?
                @subscription.contact_id = params[:subscription][:contact_id]
              else
                @subscription.contact_id =  @current_company.contacts.find(:first, :conditions=>{:active=>true}).id
              end
              saved = false unless @subscription.save
              @sale_order_line.errors.each_full do |msg|
                @subscription.errors.add_to_base(msg)
              end
            end
            
            raise ActiveRecord::Rollback unless saved
            redirect_to :action=>:sales_products, :id=>@sale_order.id 
          end
        end
      end
      render_form
    end
  end
  
  def sale_order_lines_update
    @stock_locations = @current_company.stock_locations
    @sale_order = SaleOrder.find(:first, :conditions=>{:company_id=>@current_company.id, :id=>session[:current_sale_order]})
    @sale_order_line = find_and_check(:sale_order_line, params[:id])
    @subscription = @sale_order_line.is_a_subscription ? @current_company.subscriptions.find(:first, :conditions=>{:sale_order_id=>@sale_order.id}) : Subscription.new
    #raise Exception.new @subscription.inspect
    if request.post?
      params[:sale_order_line].delete(:company_id)
      params[:sale_order_line].delete(:order_id)
      redirect_to_back if @sale_order_line.update_attributes(params[:sale_order_line])
    end
    @title = {:value=>@sale_order_line.product.name}
    render_form
  end

  def sale_order_lines_delete
    @sale_order_line = find_and_check(:sale_order_line, params[:id])
    if request.post? or request.delete?
      redirect_to :back if @sale_order_line.destroy
    end
  end


  dyta(:sales_deliveries, :model=>:deliveries, :children=>:lines, :conditions=>{:company_id=>['@current_company.id'], :order_id=>['session[:current_sale_order]']}) do |t|
    t.column :address, :through=>:contact, :children=>:product_name
    t.column :planned_on, :children=>false
    t.column :moved_on, :children=>false
    t.column :number, :through=>:invoice, :url=>{:action=>:invoices_display}, :children=>false
    t.column :quantity
    t.column :amount
    t.column :amount_with_taxes
    t.action :deliveries_update, :if=>'RECORD.invoice_id.nil? and RECORD.moved_on.nil? '
    t.action :deliveries_delete, :if=>'RECORD.invoice_id.nil? and RECORD.moved_on.nil? ', :method=>:post, :confirm=>:are_you_sure
  end


 
  dyta(:undelivered_quantities, :model=>:sale_order_lines, :conditions=>{:company_id=>['@current_company.id'], :order_id=>['session[:current_sale_order]']}) do |t|
    t.column :name, :through=>:product
    t.column :amount, :through=>:price, :label=>tc('price')
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :amount
    t.column :amount_with_taxes
    t.column :undelivered_quantity
  end

  def sales_deliveries
    @sale_order = find_and_check(:sale_order, params[:id])
    session[:current_sale_order] = @sale_order.id
    @deliveries = Delivery.find_all_by_company_id_and_order_id(@current_company.id, @sale_order.id)
    if @deliveries.empty?
      redirect_to :action=>:deliveries_create
    else
      @sale_order_lines = SaleOrderLine.find(:all,:conditions=>{:company_id=>@current_company.id, :order_id=>@sale_order.id})
      @undelivered = false
      for line in @sale_order_lines
        @undelivered = true if line.undelivered_quantity > 0 and !@undelivered
      end
      
      
      session[:current_sale_order] = @sale_order.id
      @delivery_lines = []
      for delivery in @deliveries
        lines = DeliveryLine.find_all_by_company_id_and_delivery_id(@current_company.id, delivery.id)
        @delivery_lines += lines if !lines.nil?
      end
      if @sale_order_lines == []
        flash[:warning]=tc(:no_lines_found)
        redirect_to :action=>:sales_products, :id=>session[:current_sale_order]
      end
      if request.post?
        @sale_order.update_attribute(:state, 'I') if @sale_order.state == 'L'
        redirect_to :action=>:sales_invoices, :id=>@sale_order.id
      end
    end
  end


  def sum_calculate
    @sale_order = find_and_check(:sale_orders,session[:current_sale_order])
    @sale_order_lines = @sale_order.lines
    @delivery = Delivery.new(params[:delivery])
    @delivery_lines = DeliveryLine.find_all_by_company_id_and_delivery_id(@current_company.id, session[:current_delivery])
    for lines in  @sale_order_lines
      @delivery.amount_with_taxes += (lines.price.amount_with_taxes*(params[:delivery_line][lines.id.to_s][:quantity]).to_f)
      @delivery.amount += (lines.price.amount*(params[:delivery_line][lines.id.to_s][:quantity]).to_f)
    end
  end

  def deliveries_create
    @delivery_form = "delivery_form"
    @sale_order = find_and_check(:sale_orders,session[:current_sale_order])
    @sale_order_lines = @sale_order.lines
    if @sale_order_lines.empty?
      flash[:warning]=lc(:no_lines_found)
      redirect_to :action=>:sales_deliveries, :id=>session[:current_sale_order]
    end
    @delivery_lines =  @sale_order_lines.collect{|x| DeliveryLine.new(:order_line_id=>x.id, :quantity=>x.undelivered_quantity)}
    @delivery = Delivery.new(:amount=>@sale_order.undelivered("amount"), :amount_with_taxes=>@sale_order.undelivered("amount_with_taxes"), :planned_on=>Date.today)
    session[:current_delivery] = @delivery.id
    @contacts = Contact.find(:all, :conditions=>{:company_id=>@current_company.id, :active=>true, :entity_id=>@sale_order.client_id})
    
    if request.post?
      @delivery = Delivery.new(params[:delivery])
      @delivery.order_id = @sale_order.id
      @delivery.company_id = @current_company.id
      
      ActiveRecord::Base.transaction do
        saved = @delivery.save
        if saved
          for line in @sale_order_lines
            if params[:delivery_line][line.id.to_s][:quantity].to_f > 0
              delivery_line = DeliveryLine.new(:order_line_id=>line.id, :delivery_id=>@delivery.id, :quantity=>params[:delivery_line][line.id.to_s][:quantity], :company_id=>@current_company.id)
              saved = false unless delivery_line.save
              delivery_line.errors.each_full do |msg|
                @delivery.errors.add_to_base(msg)
              end
            end
          end
        end
        raise ActiveRecord::Rollback unless saved  
        redirect_to :action=>:sales_deliveries, :id=>session[:current_sale_order] 
      end
    end
    render_form(:id=>@delivery_form)
  end
  
  def deliveries_update
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
            puts "DDDDDDDDDDDDDDDDDDD                "+saved.to_s
            line.errors.each_full do |msg|
              @delivery.errors.add_to_base(msg)
            end
          end
        end
        raise ActiveRecord::Rollback unless saved
        redirect_to :action=>:sales_deliveries, :id=>session[:current_sale_order] 
      end
    end
    render_form(:id=>@delivery_form)
  end
 

  def deliveries_delete
    @delivery = find_and_check(:deliveries, params[:id])
    if request.post? or request.delete?
      redirect_to_back if @delivery.destroy
    end
  end

  dyta(:delivery_modes, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :code
    t.column :comment
    t.action :delivery_modes_update, :image=>:update
    t.action :delivery_modes_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
  end

  def delivery_modes
  end

  def delivery_modes_create
    @delivery_mode = DeliveryMode.new
    if request.post?
      @delivery_mode = DeliveryMode.new(params[:delivery_mode])
      @delivery_mode.company_id = @current_company.id
      redirect_to_back if @delivery_mode.save
    end
    render_form
  end

  def delivery_modes_update
    @delivery_mode = find_and_check(:delivery_mode, params[:id])
    if request.post?
      redirect_to_back if @delivery_mode.update_attributes(params[:delivery_mode])
    end
    @title = {:value=>@delivery_mode.name}
    render_form
  end
   
  def delivery_modes_delete
    @delivery_mode = find_and_check(:delivery_mode, params[:id])
    if request.post?
      redirect_to_back if @delivery_mode.destroy
    end
  end

  dyta(:invoices, :conditions=>{:company_id=>['@current_company.id'],:sale_order_id=>['session[:current_sale_order]']}) do |t|
    t.column :number
    t.column :address, :through=>:contact
    t.column :amount
    t.column :amount_with_taxes
    t.action :invoices_print
  end
  
  def invoices_print
    @invoice = find_and_check(:invoice, params[:id])
    if @current_company.default_contact.nil? || @invoice.contact.nil?
      entity = @current_company.default_contact.nil? ? @current_company.name : @invoice.client.full_name
      flash[:warning]=tc(:no_contacts, :name=>entity)
      redirect_to_back
    else
      @lines = []
      @lines =  @current_company.default_contact.address.split(",").collect{ |x| x.strip}
      @lines <<  @current_company.default_contact.phone if !@current_company.default_contact.phone.nil?
      @client_address = @invoice.contact.address.split(",").collect{ |x| x.strip}
      print(@invoice)
    end
  end

  def sales_invoices
    #raise Exception.new @current_company.parameters.find_by_name("accountancy.default_journals.sales").record_value_id.inspect
    seq =  @current_company.parameter("management.invoicing.numeration").value
    #raise Exception.new @current_company.parameters.find_by_name("management.invoicing.numeration").next_value.inspect
    #raise Exception.new seq.next_value.inspect
    #a = seq.next_value
    #puts  seq.compute
    #puts seq.next_value.inspect

    @sale_order = find_and_check(:sale_order, params[:id])
    session[:current_sale_order] = @sale_order.id
    @deliveries = Delivery.find(:all,:conditions=>{:company_id=>@current_company.id, :order_id=>@sale_order.id})
    @delivery_lines = []
    @rest_to_invoice = false
    for delivery in @deliveries
      @rest_to_invoice = true if delivery.invoice_id.nil?
      lines = DeliveryLine.find_all_by_company_id_and_delivery_id(@current_company.id, delivery.id)
      @delivery_lines += lines if !lines.nil?
    end
    if request.post?
      @sale_order.update_attribute(:state, 'R') if @sale_order.state == 'I'
      saved = false
      ActiveRecord::Base.transaction do
        if params[:delivery].nil?
          invoice = Invoice.find(:first, :conditions=>{:company_id=>@current_company.id, :sale_order_id=>@sale_order.id})
          if invoice.nil?
            saved = @current_company.invoice(@sale_order)
          else
            saved = true
            flash[:message] = tc('messages.invoice_already_created')
          end 
        else
          deliveries = params[:delivery].collect{|x| Delivery.find_by_id_and_company_id(x[0],@current_company.id)}
          for delivery in deliveries
            delivery.stocks_moves_create if !delivery.moved_on.nil?
          end
          saved = @current_company.invoice(deliveries)
        end
        raise ActiveRecord::Rollback unless saved
      end
      redirect_to :action=>:sales_invoices, :id=>@sale_order.id
    end
    
    
  end
  
  
  dyta(:embankments, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :amount, :url=>{:action=>:embankments_display}
    t.column :payments_number
    t.column :name, :through=>:bank_account
    t.column :created_on
    t.action :embankments_display
    t.action :embankments_print
    t.action :embankments_update, :if=>'RECORD.locked == false'
    t.action :embankments_delete, :method=>:post, :confirm=>:are_you_sure, :if=>'RECORD.locked == false'
  end

  dyta(:embankment_payments, :model=>:payments, :conditions=>{:company_id=>['@current_company.id'], :embankment_id=>['session[:embankment_id]']}) do |t|
    t.column :full_name, :through=>:entity
    t.column :bank
    t.column :account_number
    t.column :check_number
    t.column :paid_on
    t.column :amount
  end

  def embankments
  end

  def embankments_display
    @embankment = find_and_check(:embankment, params[:id])
    session[:embankment_id] = @embankment.id
    @title = {:date=>@embankment.created_on}
  end
  
  def embankments_print
    @embankment = find_and_check(:embankment, params[:id])
    if @current_company.default_contact.nil? || @embankment.bank_account.address.nil?
      entity = @current_company.default_contact.nil? ? @current_company.name : @embankment.bank_account.name
      flash[:warning]=tc(:no_contacts, :name=>entity)
      redirect_to_back
    else
      @payments = @current_company.payments.find_all_by_embankment_id(@embankment.id)
      @lines = []
      @lines =  @current_company.default_contact.address.split(",").collect{ |x| x.strip}
      @lines <<  @current_company.default_contact.phone if !@current_company.default_contact.phone.nil?
      #raise Exception.new @embankment.bank_account.bank_name.inspect
      @account_address = @embankment.bank_account.address.split("\n")
      #raise Exception.new Payment.content_columns.inspect
    end
  end

  def embankments_create
    if @current_company.checks_to_embank(0).size == 0
      flash[:warning]=tc(:no_check_to_embank)
      redirect_to :action=>:embankments
    else
      @embankment = Embankment.new(:created_on=>Date.today)
      if request.post?
        @embankment = Embankment.new(params[:embankment])
        @embankment.mode_id = @current_company.payment_modes.find(:first, :conditions=>{:mode=>"check"}).id  if @current_company.payment_modes.find_all_by_mode("check").size == 1
        @embankment.company_id = @current_company.id 
        redirect_to :action=>:embankment_checks_create, :id=>@embankment.id if @embankment.save
      end
      render_form
    end
  end
  
  def embankments_update
    @embankment = find_and_check(:embankment, params[:id])
    if request.post?
      redirect_to :action=>:embankment_checks_update, :id=>@embankment.id if @embankment.update_attributes(params[:embankment])
    end
    @title = {:date=>@embankment.created_on}
    render_form
  end

  def embankments_delete
    @embankment = find_and_check(:embankment, params[:id])
    if request.post? or request.delete?
      redirect_to_current if @embankment.destroy
    end
  end

  def embankment_checks_create
    @embankment = find_and_check(:embankment, params[:id])
    @checks = @current_company.checks_to_embank(@embankment.mode_id)
    if request.post?
      payments = params[:check].collect{|x| Payment.find_by_id_and_company_id(x[0],@current_company.id)} if !params[:check].nil?
      if !payments.nil?
        for payment in payments
          payment.update_attributes!(:embankment_id=>@embankment.id)
        end
      end
      redirect_to :action=>:embankments
    end
  end

  def embankment_checks_update
    @embankment = find_and_check(:embankment, params[:id])
    @checks = @current_company.checks_to_embank_on_update(@embankment)
    if request.post?
      if params[:check].nil?
        flash[:warning]=tc(:choose_one_check_at_less)
        redirect_to_current
      else

        for check in @embankment.checks
          if params[:check][check.id.to_s].nil?
            check.update_attributes(:embankment_id=>nil) 
            @embankment.save
          end
        end
        payments = params[:check].collect{|x| Payment.find_by_id_and_company_id(x[0],@current_company.id)} if !params[:check].nil?
        for payment in payments
          payment.update_attributes(:embankment_id=>@embankment.id) if payment.embankment_id.nil?
        end
        redirect_to :action=>:embankments
      end
      
    end
    
  end
  
  dyta(:payment_modes, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :label, :through=>:account
    t.action :payment_modes_update, :image=>:update
    t.action :payment_modes_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
  end
  
  def payment_modes
  end

  def payment_modes_create
    if request.post?
      @payment_mode = PaymentMode.new(params[:payment_mode])
      @payment_mode.company_id = @current_company.id
      redirect_to_back if @payment_mode.save
    else
      @payment_mode = PaymentMode.new(:mode=>"other")
    end
    render_form
  end

  def payment_modes_update
    @payment_mode = find_and_check(:payment_modes, params[:id])
    if request.post?
      redirect_to_back if @payment_mode.update_attributes(params[:payment_mode])
    end
    render_form
  end

  def payment_modes_delete
    @payment_mode = find_and_check(:payment_modes, params[:id])
    if request.post? or request.delete?
      redirect_to_back if @payment_mode.destroy
    end
  end

  dyta(:payment_parts, :conditions=>{:company_id=>['@current_company.id'], :order_id=>['session[:current_sale_order]']}) do |t|
    t.column :amount, :through=>:payment, :label=>tc('payment_amount')
    t.column :amount
    t.column :payment_way
    t.column :paid_on, :through=>:payment, :label=>tc('paid_on')
    t.action :payments_update, :image=>:update
    t.action :payments_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
  end

  
  def sales_payments
    @sale_order = find_and_check(:sale_orders, params[:id]||session[:current_sale_order])
    @payments = @sale_order.payment_parts
    @invoices = @sale_order.invoices
    @invoices_sum = 0
    @invoices.each {|i| @invoices_sum += i.amount_with_taxes}
    @payments_sum = 0 
    @payments.each {|p| @payments_sum += p.amount}
    session[:current_sale_order] = @sale_order.id
    #raise Exception.new @sale_order.client.balance.inspect
    if request.post?
      @sale_order.update_attribute(:state, 'F') if @sale_order.state == 'R'
      #redirect_to :action=>:sales_payments, :id=>@sale_order.id
    end
  end
 

  def payments_create
    @sale_order = find_and_check(:sale_orders, session[:current_sale_order])
    if @sale_order.rest_to_pay <= 0
      flash[:notice]=tc(:error_sale_order_already_paid)
      redirect_to :action=>:sales_payments, :id=>@sale_order.id
    else
      @modes = ["new","existing_part"]
      @update = false
      @payments = @sale_order.payments 
      if request.post?
        if params[:price][:mode] == "new"
          @payment = Payment.new(params[:payment])
          @payment.company_id = @current_company.id
          @payment.entity_id = @sale_order.client_id
          @sale_order.add_payment(@payment) if @payment.save
        else
          @payment = find_and_check(:payment, params[:pay][:part])
          payment_part = PaymentPart.find(:first, :conditions=>{:company_id=>@current_company.id, :payment_id=>@payment.id})
          @sale_order.add_part(@payment)
        end
        redirect_to :action=>:sales_payments, :id=>@sale_order.id
      else
        @payment = Payment.new(:paid_on=>Date.today, :to_bank_on=>Date.today, :amount=>@sale_order.rest_to_pay)
       #  mode = PaymentMode.find(:first, :conditions=>{:company_id=>@current_company.id})
#         if !mode.nil?
#           @payment = Payment.new(:mode_id=>mode.id)
#           @check_infos = true if mode.mode == "check"
#         else
#           @payment = Payment.new
#         end
      end
      @title = {:value=>@sale_order.number}
      render_form
    end
  end
  
  def payments_update
    @update = true
    @sale_order = find_and_check(:sale_order, session[:current_sale_order])
    @payment_part = find_and_check(:payment_part, params[:id])
    @payment = Payment.new(:amount=>@payment_part.amount, :paid_on=>@payment_part.payment.paid_on, :mode_id=>@payment_part.payment.mode_id)
    if request.post?
      @payment = @payment_part.payment
      amount = PaymentPart.find(:first, :conditions=>{:company_id=>@current_company.id, :payment_id=>@payment.id}).amount
      conditions = ((@payment.amount != @payment.part_amount or amount != @payment.amount) and ((params[:payment][:amount].to_d <= (@sale_order.rest_to_pay + @payment_part.amount)) and ((@payment.part_amount + (params[:payment][:amount].to_d - @payment_part.amount)) <= @payment.amount ) ) )
      if conditions
        old_value = @payment_part.amount
        @payment_part.update_attributes(:amount=>params[:payment][:amount])
        new_part_amount = (@payment.part_amount + params[:payment][:amount].to_d - old_value)
        @payment.update_attributes!(:paid_on=>params[:payment][:paid_on], :mode_id=>params[:payment][:mode_id], :part_amount=>new_part_amount)

      elsif (!(@payment.amount != @payment.part_amount or amount != @payment.amount) and (params[:payment][:amount].to_d <= ( @sale_order.amount_with_taxes - (PaymentPart.sum(:amount, :conditions=>{:order_id=>@sale_order.id,:company_id=>@sale_order.company_id}) - @payment_part.amount))) ) 
        @payment.update_attributes!(:amount=>params[:payment][:amount],:paid_on=>params[:payment][:paid_on], :mode_id=>params[:payment][:mode_id], :part_amount=>params[:payment][:amount])
        @payment_part.update_attributes!(:amount=>params[:payment][:amount])
      else
        flash[:warning]=tc(:amount_out_of_limits)
      end
      redirect_to :action=>:sales_payments, :id=>@sale_order.id 
    end
    render_form 
  end

  def payments_delete
    @sale_order = find_and_check(:sale_order, session[:current_sale_order])
    @payment_part = find_and_check(:payment_part, params[:id])
    if request.post? or request.delete?
      redirect_to :action=>:sales_payments, :id=>@sale_order.id if  @payment_part.destroy
      # ## +up payment ? -> amount ds model prend ts les part_amount correspondant
      # @payment = @payment_part.payment
      # @payment.update_attributes(:part_amount=>(@payment.part_amount - @payment_part.amount)) 
      # redirect & destroy p + pp
      #    
    end
  end
  

  dyta(:shelves, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :comment
    t.column :catalog_name
    t.column :catalog_description
    t.column :name, :through=>:parent
    t.action :shelves_update, :image=>:update
    t.action :shelves_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
  end

  def shelves
   # shelves_list params
  end

  def shelves_display
    @shelf = find_and_check(:shelf, params[:id])
    @title = {:value=>@shelf.name}
  end

  def shelves_create
    if request.post? 
      @shelf = Shelf.new(params[:shelf])
      @shelf.company_id = @current_company.id
      redirect_to_back if @shelf.save
    else
      @shelf = Shelf.new
    end
    render_form
  end

  def shelves_update
    @shelf = find_and_check(:shelf, params[:id])
    if request.post?
      params[:shelf][:company_id] = @current_company.id
      redirect_to_back if @shelf.update_attributes(params[:shelf])
    end
    render_form(:label=>@shelf.name)
  end

  def shelves_delete
    @shelf = find_and_check(:shelf, params[:id])
    if request.post? or request.delete?
      redirect_to :back if @shelf.destroy
    end
  end


  dyta(:stock_locations, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :name, :through=>:establishment
    t.column :name, :through=>:parent
    t.column :reservoir
    t.action :stocks_locations_display, :image=>:show
    #t.action :stocks_locations_update, :mode=>:reservoir, :image=>:update, :if=>'RECORD.reservoir == true'
    t.action :stocks_locations_update, :image=>:update
    #t.action :stocks_locations_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
  end

  dyta(:stock_moves, :conditions=>{:company_id=>['@current_company.id'], :location_id=>['session[:current_stock_location_id]']}) do |t|
    t.column :name
    t.column :planned_on
    t.column :moved_on
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :name, :through=>:product
    t.column :virtual
    t.action :stocks_moves_update, :image=>:update, :if=>'RECORD.generated != true'
    t.action :stocks_moves_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure,:if=>'RECORD.generated != true' 
  end
  
  def stocks_locations
    # stock_locations_list params
  
    unless @current_company.stock_locations.size>0
      flash[:message] = tc('messages.need_stock_location_to_record_stock_moves')
      redirect_to :action=>:stocks_locations_create
      return
    end
  end

  def stocks_locations_display
    @stock_location = find_and_check(:stock_location, params[:id])
    session[:current_stock_location_id] = @stock_location.id
    #stock_moves_list 
    @title = {:value=>@stock_location.name}
  end

  def stocks_locations_create
    @mode = (params[:mode]||session[:location_type]||:original).to_sym
    session[:location_type] = @mode
    if request.post? 
      #raise Exception.new params.inspect
      @stock_location = StockLocation.new(params[:stock_location])
      @stock_location.company_id = @current_company.id
      if @stock_location.save
        if session[:history][1].to_s.include? "stocks" 
          redirect_to :action=>:stocks_locations_display, :id=>@stock_location.id
        else
          redirect_to_back
        end
      end
    else
      @stock_location = StockLocation.new
    end
    render_form
  end

  def stocks_locations_update
    @stock_location = find_and_check(:stock_location, params[:id])
    @mode = :reservoir if @stock_location.reservoir
    if request.post?
      if @stock_location.update_attributes(params[:stock_location])
        redirect_to :action=>:stocks_locations_display, :id=>@stock_location.id
      end
    end
    render_form(:label=>@stock_location.name)
  end

  def stocks_locations_delete
    @stock_location = find_and_check(:stock_location, params[:id])
    if request.post? or request.delete?
      redirect_to :back if @stock_location.destroy
    end
  end

  def stocks_moves_create
    @stock_location = StockLocation.find_by_id session[:current_stock_location_id]
    if request.post? 
      @stock_move = StockMove.new(params[:stock_move])
      @stock_move.company_id = @current_company.id
      # @stock_move.virtual = true
      # @stock_move.input = true
      #if @stock_move.save
        # @stock_move.change_quantity
      redirect_to :action =>:stocks_locations_display, :id=>@stock_move.location_id if @stock_move.save
      #end
    else
      @stock_move = StockMove.new
      @stock_move.planned_on = Date.today
    end
    render_form
  end

  def stocks_moves_update
    @stock_move = find_and_check(:stock_move, params[:id])
    if request.post?
      redirect_to :action=>:stocks_locations_display, :id=>@stock_move.location_id if @stock_move.update_attributes(params[:stock_move])
    end
    @title = {:value=>@stock_move.name}
    render_form
  end

  def stocks_moves_delete 
    @stock_move = find_and_check(:stock_move, params[:id])
    if request.post? or request.delete?
      redirect_to :back if @stock_move.destroy
    end
  end

  dyta(:subscription_natures, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :read_nature
    t.column :actual_number
    t.action :subscription_natures_down, :method=>:post, :if=>"RECORD.nature=='quantity'"
    t.action :subscription_natures_up, :method=>:post, :if=>"RECORD.nature=='quantity'"
    t.action :subscription_natures_display
    t.action :subscription_natures_update
  end

  def subscription_natures
  end

  def subscription_natures_create
    @subscription_nature = SubscriptionNature.new
    @subscription_nature.nature = SubscriptionNature.natures.first[1]
    if request.post?
      @subscription_nature = SubscriptionNature.new(params[:subscription_nature])
      @subscription_nature.company_id = @current_company.id
      redirect_to_back if @subscription_nature.save
    end
    render_form
  end

  def subscription_natures_update
    @subscription_nature = find_and_check(:subscription_nature, params[:id])
    if request.post?
    end
    @title = {:value=>@subscription_nature.name}
    render_form
  end

  def subscription_natures_display
    @subscription_nature = find_and_check(:subscription_nature, params[:id])
    session[:subscription_nature] = @subscription_nature
    redirect_to :action=>:subscriptions, :nature=>@subscription_nature.id
  end

  def subscription_natures_up
    if request.post?
      #raise Exception.new "tt"+params.inspect
      @subscription_nature = find_and_check(:subscription_nature, params[:id])
      if !@subscription_nature.nil?
        @subscription_nature.actual_number += 1
        @subscription_nature.save
      end
      flash[:notice]=tc('new_actual_number', :value=>@subscription_nature.actual_number)
      redirect_to_back
    end
  end

  def subscription_natures_down
    if request.post?
      @subscription_nature = find_and_check(:subscription_nature, params[:id])
      if !@subscription_nature.nil?
        @subscription_nature.actual_number -= 1
        @subscription_nature.save
      end
      flash[:notice]=tc('new_actual_number', :value=>@subscription_nature.actual_number)
      redirect_to_back
    end
  end

  dyta(:subscriptions, :conditions=>:subscriptions_conditions ) do |t|
    t.column :entity_name
    t.column :line_2, :through=>:contact, :label=>"Dest-Serv"
    t.column :line_3, :through=>:contact, :label=>"Bat./Rés."
    t.column :line_4_number, :through=>:contact, :label=>"N° voie"
    t.column :line_4_street, :through=>:contact, :label=>"Libelle voie"
    t.column :line_5, :through=>:contact, :label=>"Lieu dit"
    t.column :line_6_code, :through=>:contact, :label=>"Code postal"
    t.column :line_6_city, :through=>:contact, :label=>"Ville"
    t.column :name, :through=>:product
    #t.column :started_on
    #t.column :finished_on
    #t.column :first_number
    #t.column :last_number
    t.column :beginning
    t.column :finish
  end

  def subscription_options_display
    
    @subscription_nature = find_and_check(:subscription_nature, params[:subscription_nature_id])
    # raise Exception.new params.inspect+"kkkkkkkkkkkkkkkkkkkk"+@subscription_nature.inspect
    
  end
  
  def subscriptions
    if @current_company.subscription_natures.size == 0
      flash[:warning]=tc(:need_to_create_subscription_nature)
      redirect_to :action=>:subscription_natures
    else 
      session[:sub_is_date] = 0 
      if not params[:nature].nil?
        @subscription_nature = find_and_check(:subscription_nature, params[:nature])
        session[:subscription_instant] = @subscription_nature.nature == "quantity" ? @subscription_nature.actual_number : Date.today
        session[:sub_is_date] = @subscription_nature.nature == "quantity" ? 2 : 1
      else
        @subscription_nature = session[:subscription_nature]||@current_company.subscription_natures.find(:first)
      end
      session[:subscription_nature] = @subscription_nature
    end
    if request.post?
      @subscription_nature = find_and_check(:subscription_nature, params[:subscription_nature][:id])
      if @subscription_nature
        if @subscription_nature.nature == "quantity"
          session[:subscription_instant]= params[:subscription][:value].to_i > 0 ? params[:subscription][:value].to_i : 0
          session[:sub_is_date] = 2
        elsif @subscription_nature.nature == "period" and !params[:subscription][:value].nil?
          begin
            params_to_date = params[:subscription][:value].to_date
            session[:subscription_instant] = params_to_date
            session[:sub_is_date] = 1
          rescue
            session[:subscription_instant] = Date.today
            session[:sub_is_date] = 1
            flash[:warning]=tc(:unvalid_date)
          end
        end
      end
    end
  end
  
  
  
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
        delivery.stocks_moves_create if delivery and values[:delivered].to_i == 1
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
      #raise Exception.new params.inspect
      for id, values in params[:unvalidated_embankments]
        embankment = Embankment.find_by_id_and_company_id(id, @current_company.id)
        embankment.update_attributes!(:locked=>true) if embankment and values[:validated].to_i == 1
      end
      redirect_to :action=>:unvalidated_embankments
    end
  end
  
  dyta(:product_stocks, :conditions=>:stocks_conditions, :line_class=>'RECORD.state') do |t|
    t.column :name, :through=>:product,:url=>{:action=>:products_display}
    t.column :weight, :through=>:product, :label=>"Poids"
    t.column :quantity_max
    t.column :quantity_min
    t.column :critic_quantity_min
    t.column :current_virtual_quantity
    t.column :current_real_quantity
  end

  dyta(:critic_product_stocks, :model=>:product_stocks, :conditions=>['company_id = ? AND current_virtual_quantity <= critic_quantity_min AND product_id = ?', ['@current_company.id'], ['session[:product_id]']] , :line_class=>'RECORD.state') do |t|
    t.column :name, :through=>:product,:url=>{:action=>:products_display}
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
      redirect_to :action=>:stocks_locations_create
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
    t.action :stock_transfers_update, :image=>:update
    t.action :stock_transfers_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
  end

  def stock_transfers
  end

  def stock_transfers_create
    @stock_transfer = StockTransfer.new(:nature=>"transfer", :planned_on=>Date.today)
    if request.post?
      #raise Exception.new(params.inspect)
      @stock_transfer = StockTransfer.new(params[:stock_transfer])
      @stock_transfer.company_id = @current_company.id
      redirect_to_back if @stock_transfer.save
    end
    render_form
  end

  def stock_transfers_update
    @stock_transfer = find_and_check(:stock_transfer, params[:id])
    if request.post?
      #raise Exception.new params.inspect
      redirect_to_back if @stock_transfer.update_attributes!(params[:stock_transfer])
    end
    render_form
  end
  
  def stock_transfers_delete
    @stock_transfer = find_and_check(:stock_transfer, params[:id])
    if request.post? or request.delete?
      redirect_to_back if @stock_transfer.destroy
    end
  end

  dyta(:taxes, :conditions=>{:company_id=>['@current_company.id'], :deleted=>false}) do |t|
    t.column :name
    t.column :amount, :precision=>3
    t.column :text_nature
    t.column :included
    t.column :reductible
    t.action :taxes_update, :image=>:update
    t.action :taxes_delete, :image=>:delete, :method=>:post
  end
  
  def taxes
  end
 

  def taxes_create
    @tax = Tax.new(:nature=>:percent)
    if request.post?
       @tax = Tax.new(params[:tax])
      @tax.company_id = @current_company.id
      redirect_to :action=>:taxes if @tax.save
    end
    render_form
  end

  def taxes_update
    @tax = find_and_check(:tax, params[:id])
    if request.post?
      redirect_to :action=>:taxes if @tax.update_attributes!(params[:tax])
    end
    @title = {:value=>@tax.name}
    render_form
  end
  
  def taxes_delete
    @tax = find_and_check(:tax, params[:id])
    if request.post? or request.delete?
      redirect_to :action=>:taxes if @tax.destroy
    end
  end
  
end
