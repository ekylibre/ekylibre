class ManagementController < ApplicationController

  include ActionView::Helpers::FormOptionsHelper

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
  end

  dyta(:delays, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :active
    t.column :expression
    t.column :comment
    t.action :delays_display, :image=>:show
    t.action :delays_update, :image=>:update
    t.action :delays_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
    t.procedure :delays_create
  end

  def delays
    delays_list params
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
  
  
  dyta(:prices, :conditions=>:prices_conditions) do |t|
    t.column :name, :through=>:product, :url=>{:action=>:products_display}
    t.column :full_name, :through=>:entity
    t.column :amount
    t.column :amount_with_taxes
    t.column :default
    t.column :range
    t.action :prices_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
    # t.procedure :sales_prices_create,     :action=>:prices_create, :mode=>:sales
    # t.procedure :purchases_prices_create, :action=>:prices_create, :mode=>:purchases
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
    prices_list params
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
        @price = Price.new 
      end
    end
    render_form    
  end
  
  def prices_delete
    @price = find_and_check(:price, params[:id])
    if request.post? or request.delete?
      @price.update_attributes(:active=>false)
    end
    redirect_to_back
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
    t.procedure :new_product, :action=>:products_create
  end
  
  dyta(:product_prices, :conditions=>{:company_id=>['@current_company.id'], :product_id=>['session[:product_id]'], :active=>true}, :model=>:prices) do |t|
    t.column :name, :through=>:entity
    t.column :amount
    t.column :amount_with_taxes
    t.column :default
    t.column :range
    t.action :prices_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
    #t.procedure :sales_prices_create,     :action=>:prices_create, :mode=>:sales, :product_id=>['session[:product_id]']
    #t.procedure :purchases_prices_create, :action=>:prices_create, :mode=>:purchases, :product_id=>['session[:product_id]']
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
    @key = params[:key]||session[:product_key]
    session[:product_key] = @key
    products_list({:attributes=>[:id, :name, :description, :catalog_name, :catalog_description, :comment], :key=>@key}.merge(params))
  end

  def products_display
    @product = find_and_check(:product, params[:id])
    session[:product_id] = @product.id
    product_prices_list params
    product_components_list 
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
    if @stock_locations.size < 1
      flash[:warning]=tc('need_stocks_location_to_create_products')
      redirect_to :action=>:stocks_locations_create
    end
    if request.post? 
      @product = Product.new(params[:product])
      @product.company_id = @current_company.id
      ActiveRecord::Base.transaction do
        saved = @product.save
        if params[:product][:without_stocks] == "0"
          if saved
            @product_stock = ProductStock.new(params[:product_stock])
            @product_stock.product_id = @product.id
            @product_stock.company_id = @current_company.id
            saved = false unless @product_stock.save!
            @product_stock.errors.each_full do |msg|
              @product.errors.add_to_base(msg)
            end
          end
        end 
        raise ActiveRecord::Rollback unless saved  
      end
      redirect_to_back
    else
      @product = Product.new(:without_stocks=>true)
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
    if @product.without_stocks
      @product_stock = ProductStock.new
    else
      @product_stock = ProductStock.find(:first, :conditions=>{:company_id=>@current_company.id ,:product_id=>@product.id} )||ProductStock.new 
    end
    if request.post?
      if @product.update_attributes(params[:product])
        if @product_stock.id.nil? and params[:product][:without_stocks] == "0"
          @product_stock = ProductStock.new(params[:product_stock])
          @product_stock.product_id = @product.id
          @product_stock.company_id = @current_company.id 
        elsif !@product_stock.id.nil? and @stock_locations.size > 1
          @product_stock.add_or_update(params[:product_stock],@product.id)
        else
          @product_stock.update_attributes(params[:product_stock])
        end
        redirect_to :action=>:products_display, :id=>@product.id
      end
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
    t.column :shipped
    t.column :invoiced
    t.column :amount
    t.column :amount_with_taxes
  end

  def purchases
    purchase_orders_list params
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
    purchase_order_lines_list params
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
    sale_orders_list params
  end
  
  dyta(:sale_lines, :conditions=>{:company_id=>['@current_company.id'], :order_id=>['session[:current_sale_order]']},:model=>:sale_order_lines,:empty=>true) do |t|
    t.column :name, :through=>:product
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :amount, :through=>:price
    t.column :amount
    t.column :amount_with_taxes
  end

  dyta(:deliveries, :conditions=>{:company_id=>['@current_company.id'], :order_id=>['session[:current_sale_order]']}, :children=>:lines) do |t|
    t.column :text_nature, :children=>:product_name
    t.column :planned_on, :children=>false
    t.column :moved_on, :children=>false
    t.column :amount
    t.column :amount_with_taxes
  end

  dyta(:invoice_lines, :model=>:invoices, :conditions=>{:company_id=>['@current_company.id'],:sale_order_id=>['session[:current_sale_order]']}, :children=>:lines) do |t|
    t.column :number, :children=>false
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
    sale_lines_list
    deliveries_list
    invoice_lines_list
    payments_list
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
    t.procedure :sale_order_natures_create
  end

  def sale_order_natures
    sale_order_natures_list params
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
    #contacts = Contact.find_all_by_entity_id_and_company_id(client_id, @current_company.id)||[]
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
    t.column :amount, :through=>:price
    t.column :amount
    t.column :amount_with_taxes
    t.action :sale_order_lines_update, :image=>:update, :if=>'RECORD.order.state == "P"'
    t.action :sale_order_lines_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure, :if=>'RECORD.order.state == "P"'
    #t.procedure :sale_order_lines_create, :if=>'RECORD.order.state == "P"'
  end

  def sales_products
    @sale_order = find_and_check(:sale_order, params[:id])
    session[:current_sale_order] = @sale_order.id
    @stock_locations = @current_company.stock_locations
    @entity = @sale_order.client
    sale_order_lines_list params
    if request.post?
      if @sale_order.state == 'L'
        flash[:warning]=tc('sale_order_already_ordered')
      else
        @sale_order.confirmed_on = Date.today
        @sale_order.update_attribute(:state, 'L') if @sale_order.state == 'P'
        @sale_order.stocks_moves_create
      end
      redirect_to :action=>:sales_deliveries, :id=>@sale_order.id
    end
    @title = {:client=>@entity.full_name, :sale_order=>@sale_order.number}
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


  def sale_order_lines_create
    @stock_locations = @current_company.stock_locations
    @sale_order = SaleOrder.find(:first, :conditions=>{:company_id=>@current_company.id, :id=>session[:current_sale_order]})
    if @stock_locations.empty? 
      flash[:warning]=tc(:need_stock_location_to_create_sale_order_line)
      redirect_to :action=>:stocks_locations_create
    elsif @sale_order.state == 'L'
      flash[:warning]=tc(:impossible_to_add_lines)
      redirect_to :action=>:sales_products, :id=>@sale_order.id
    else
      if request.post? 
        @sale_order_line = @current_company.sale_order_lines.find(:first, :conditions=>{:price_id=>params[:sale_order_line][:price_id], :order_id=>session[:current_sale_order]})
        if @sale_order_line
          @sale_order_line.quantity += params[:sale_order_line][:quantity].to_d
        else
          @sale_order_line = SaleOrderLine.new(params[:sale_order_line])
          @sale_order_line.company_id = @current_company.id
          @sale_order_line.order_id = session[:current_sale_order]
          @sale_order_line.product_id = find_and_check(:prices,params[:sale_order_line][:price_id]).product_id
          @sale_order_line.location_id = @stock_locations[0].id if @stock_locations.size == 1
        end
        redirect_to_back if @sale_order_line.save
      else
        @sale_order_line = SaleOrderLine.new
      end
      render_form
    end
  end

  def sale_order_lines_update
    @stock_locations = @current_company.stock_locations
    @sale_order_line = find_and_check(:sale_order_line, params[:id])
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
 
  dyta(:undelivered_quantities, :model=>:sale_order_lines, :conditions=>{:company_id=>['@current_company.id'], :order_id=>['session[:current_sale_order]']}) do |t|
    t.column :name, :through=>:product
    t.column :amount, :through=>:price
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
      undelivered_quantities_list params if @undelivered
      
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
    @contacts = Contact.find(:all, :conditions=>{:company_id=>@current_company.id, :entity_id=>@sale_order.client_id})
    
    if request.post?
      @delivery = Delivery.new(params[:delivery])
      @delivery.order_id = @sale_order.id
      @delivery.company_id = @current_company.id
      
      ActiveRecord::Base.transaction do
        saved = @delivery.save
        if saved
          for line in @sale_order_lines
            line = DeliveryLine.new(:order_line_id=>line.id, :delivery_id=>@delivery.id, :quantity=>params[:delivery_line][line.id.to_s][:quantity], :company_id=>@current_company.id)
            saved = false unless line.save
            line.errors.each_full do |msg|
              line.errors.add_to_base(msg)
            end
          end
        end
        raise ActiveRecord::Rollback unless saved  
      end
      redirect_to :action=>:sales_deliveries, :id=>session[:current_sale_order] 
    end
    render_form(:id=>@delivery_form)
  end
  
  def deliveries_update
    @delivery_form = "delivery_form"
    @delivery =  find_and_check(:deliveries, params[:id])
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

  dyta(:invoices, :conditions=>{:company_id=>['@current_company.id'],:sale_order_id=>['session[:current_sale_order]']}) do |t|
    t.column :number
    t.column :address, :through=>:contact
    t.column :amount
    t.column :amount_with_taxes
  end

  def sales_invoices
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
    invoices_list params
    if request.post?
      @sale_order.update_attribute(:state, 'R') if @sale_order.state == 'I'
      if params[:delivery].nil?
        invoice = Invoice.find(:first, :conditions=>{:company_id=>@current_company.id, :sale_order_id=>@sale_order.id})
        if invoice.nil?
          @current_company.invoice(@sale_order)
        else
          flash[:message] = tc('messages.invoice_already_created')
        end
      else
        deliveries = params[:delivery].collect{|x| Delivery.find_by_id_and_company_id(x[0],@current_company.id)}
        for delivery in deliveries
          delivery.stocks_moves_create if !delivery.moved_on.nil?
        end
        @current_company.invoice(deliveries)
      end
      redirect_to :action=>:sales_invoices, :id=>@sale_order.id
    end
    
    
  end
  
  dyta(:payment_modes, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :label, :through=>:account
    t.procedure :payment_modes_create
    t.action :payment_modes_update, :image=>:update
    t.action :payment_modes_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
  end

  def payment_modes
    payment_modes_list params
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
    t.column :amount, :through=>:payment, :label=>"Montant du paiment"
    t.column :amount
    t.column :payment_way
    t.column :paid_on, :through=>:payment, :label=>"Réglé le"
    t.action :payments_update, :image=>:update
    t.action :payments_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
    t.procedure :payments_create
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
    payment_parts_list params
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
        #raise Exception.new params.inspect
        if params[:price][:mode] == "new"
          @payment = Payment.new(params[:payment])
          @payment.company_id = @current_company.id
          @sale_order.add_payment(@payment) if @payment.save
        else
          @payment = find_and_check(:payment, params[:pay][:part])
          payment_part = PaymentPart.find(:first, :conditions=>{:company_id=>@current_company.id, :payment_id=>@payment.id})
          @sale_order.add_part(@payment)
        end
        redirect_to :action=>:sales_payments, :id=>@sale_order.id
      else
        @payment = Payment.new
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
  
  def sales_print
    render(:xil=>"#{RAILS_ROOT}/app/views/prints/sale_order.xml", :key=>params[:id])
  end





  dyta(:shelves, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :comment
    t.column :catalog_name
    t.column :catalog_description
    t.column :name, :through=>:parent
    t.action :shelves_update, :image=>:update
    t.action :shelves_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
    t.procedure :shelves_create
  end

  def shelves
    shelves_list params
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
    t.action :stocks_locations_display, :image=>:show
    #t.action :stocks_locations_update, :mode=>:reservoir, :image=>:update, :if=>'RECORD.reservoir == true'
    t.action :stocks_locations_update, :image=>:update
    #t.action :stocks_locations_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
    #t.procedure :stocks_locations_create
  end

  dyta(:stock_moves, :conditions=>{:company_id=>['@current_company.id'], :location_id=>['session[:current_stock_location_id]']}) do |t|
    t.column :name
    t.column :planned_on
    t.column :moved_on
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :name, :through=>:product
    t.column :virtual
    t.action :stocks_moves_update, :image=>:update
    t.action :stocks_moves_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
    t.procedure :stocks_moves_create
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
    stock_moves_list 
    @title = {:value=>@stock_location.name}
  end

  def stocks_locations_create
    @mode = (params[:mode]||"original").to_sym
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
      @stock_move.virtual = true
      @stock_move.input = true
      if @stock_move.save
        @stock_move.change_quantity
        redirect_to :action =>:stocks_locations_display, :id=>@stock_move.location_id 
      end
    else
      @stock_move = StockMove.new
      @stock_move.planned_on = Date.today
    end
    render_form
  end

  def stocks_moves_update
    @stock_move = find_and_check(:stock_move, params[:id])
    last_quantity = @stock_move.quantity
    # render_form(:read_only=>true) if !self.moved_on.nil? or self.generated
  # else
    if request.post?
      params[:stock_move][:company_id] = @current_company.id
      if @stock_move.update_attributes(params[:stock_move])
        @stock_move.update_stock_quantity(last_quantity)
        redirect_to :action=>:stocks_locations_display, :id=>@stock_move.location_id
      end
    end
    @title = {:value=>@stock_move.name}
    render_form
  end

  def stocks_moves_delete ## => Permission ? 
    @stock_move = find_and_check(:stock_move, params[:id])
    if request.post? or request.delete?
      redirect_to :back if @stock_move.destroy
    end
  end

  def undelivered_sales
    @deliveries = Delivery.find(:all,:conditions=>{:company_id=>@current_company.id, :moved_on=>nil},:order=>"planned_on ASC")  
    @delivery_lines = []
    for delivery in @deliveries
      lines = DeliveryLine.find_all_by_company_id_and_delivery_id(@current_company.id, delivery.id)
      @delivery_lines += lines if !lines.nil?
    end
    if request.post?
      deliveries = params[:delivery].collect{|x| Delivery.find_by_id_and_company_id(x[0],@current_company.id)} if !params[:delivery].nil?
      if !deliveries.nil?
        for delivery in deliveries
          delivery.stocks_moves_create
        end
      end
      redirect_to :action=>:undelivered_sales
    end
  end


  def unexecuted_transfers
    @stock_transfers = @current_company.stock_transfers.find(:all, :conditions=>{:moved_on=>nil}, :order=>"planned_on ASC")
    if request.post?
      #raise Exception.new params.inspect
      stock_transfers = params[:stock_transfer].collect{|x| StockTransfer.find_by_id_and_company_id(x[0], @current_company.id)} if !params[:stock_transfer].nil?
      if !stock_transfers.nil?
        for stock_transfer in stock_transfers
          stock_transfer.execute_transfer
        end
      end
      redirect_to_back
    end
  end

  def unreceived_purchases
    @purchase_orders = PurchaseOrder.find(:all, :conditions=>{:company_id=>@current_company.id, :moved_on=>nil}, :order=>"planned_on ASC")
    if request.post?
      purchases = params[:purchase].collect{|x| PurchaseOrder.find_by_id_and_company_id(x[0],@current_company.id)} if !params[:purchase].nil?
      if !purchases.nil?
        for purchase in purchases
          purchase.real_stocks_moves_create
        end
      end
      redirect_to :action=>:unreceived_purchases
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
  

#   def stocks_conditions(options={})
#     conditions = {}
#     conditions[:company_id] = @current_company.id
#     conditions[:location_id] = session[:location_id] if !session[:location_id].nil?
#     conditions
#   end

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
      product_stocks_list 
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
   stock_transfers_list
  end

  def stock_transfers_create
    @stock_transfer = StockTransfer.new(:nature=>"transfer", :planned_on=>Date.today)
    if request.post?
      #raise Exception.new params.inspect
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
  
  
end
