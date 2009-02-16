class ManagementController < ApplicationController

  include ActionView::Helpers::FormOptionsHelper

  def index
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








  dyta(:price_lists, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name, :url=>{:action=>:price_lists_display}
    t.column :active
    t.column :name, :through=>:currency
    t.column :count, :through=>:prices, :label=>'Nb Prix'
    t.column :comment
    t.action :price_lists_display, :image=>:show
    t.action :price_lists_update, :image=>:update
    t.action :price_lists_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
    t.procedure :price_lists_create
  end

  dyta(:prices, :conditions=>{:company_id=>['@current_company.id'], :list_id=>['@price_list.id'], :deleted=>false}) do |t|
    t.column :name, :through=>:product, :url=>{:action=>:products_display}
    t.column :amount
    t.column :amount_with_taxes
    t.column :range
    t.action :prices_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
    t.procedure :prices_create
  end


  def price_lists
    price_lists_list params
  end

  def price_lists_display
    @price_list = find_and_check(:price_list, params[:id])    
    prices_list params
    @title = {:value=>@price_list.name}
  end

  def price_lists_create
    if request.post? 
      @price_list = PriceList.new(params[:price_list])
      @price_list.company_id = @current_company.id
      redirect_to_back if @price_list.save
    else
      @price_list = PriceList.new
    end
    render_form
  end

  def price_lists_update
    @price_list = find_and_check(:price_list, params[:id])
    if request.post?
      if @price_list.update_attributes(params[:price_list])
        redirect_to :action=>:price_lists
      end
    end
    @title = {:value=>@price_list.name}
    render_form
  end

  def price_lists_delete
    @price_list = find_and_check(:price_list, params[:id])
    if request.post? or request.delete?
      @price_list.delete
    end
    redirect_to_back
  end



  def prices_create
    if request.post? 
      if session[:last_saved_price].nil?
        @price = Price.new(params[:price])
        @price.company_id = @current_company.id
      else
        @price = Price.find session[:last_saved_price]
      end
      if @price.save
        session[:last_saved_price] = @price.id
        all_safe = true
        if params[:price_tax]
          for tax in params[:price_tax]
            tax = find_and_check(:tax, tax[0])
            @price_tax = @price.taxes.create(:tax_id=>tax.id)
#            raise Exception.new(@price_tax.inspect)
            all_safe = false unless @price_tax.save
          end
        end
        if all_safe
          session[:last_saved_price] = nil
          redirect_to_back
        end
      end
    else
      if @current_company.available_products.size<=0
        flash[:message] = tc(:messages, :need_product_to_create_price)
        redirect_to :action=> :products_create
      end
      session[:last_saved_price] = nil
      @price = Price.new
      @price.list_id = params[:id]
    end
    render_form    
  end

  def prices_delete
    @price = find_and_check(:price, params[:id])
    if request.post? or request.delete?
      @price.delete
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

  dyta(:product_prices, :conditions=>{:company_id=>['@current_company.id'], :product_id=>['@product.id'], :deleted=>false}, :model=>:prices) do |t|
    t.column :name, :through=>:list, :url=>{:action=>:price_lists_display}
    t.column :amount
    t.column :amount_with_taxes
    t.column :range
    t.action :prices_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
    t.procedure :prices_create
  end

  def products
    @key = params[:key]||session[:product_key]
    session[:product_key] = @key
    products_list({:attributes=>[:id, :name, :description, :catalog_name, :catalog_description, :comment], :key=>@key}.merge(params))
  end

  def products_display
    @product = find_and_check(:product, params[:id])
    product_prices_list params
    @title = {:value=>@product.name}
  end

  def products_create
    if request.post? 
      @product = Product.new(params[:product])
      @product.company_id = @current_company.id
      redirect_to_back if @product.save
    else
      @product = Product.new
      @product.nature = Product.natures.first[1]
      @product.supply_method = Product.supply_methods.first[1]
    end
    render_form
  end

  def products_update
    @product = find_and_check(:product, params[:id])
    if request.post?
      if @product.update_attributes(params[:product])
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
    t.column :number
    t.column :full_name, :through=>:supplier
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
      list = PriceList.find(:first,:conditions=>{:entity_id=>params[:purchase_order][:supplier_id]})
      if !list.blank?                      ## Adapté ???
        @purchase_order.list_id = list.id
      else                                           #name => nom supplier + ...          ## Currency_id ...
        new_list = PriceList.create!(:name=>"blabla price list", :started_on=>Date.today, :currency_id=>1, :entity_id=>params[:purchase_order][:supplier_id], :company_id=>@current_company.id)
        @purchase_order.list_id = new_list.id
      end
      redirect_to :action=>:purchases_products, :id=>@purchase_order.id if @purchase_order.save
    else
      @purchase_order = PurchaseOrder.new
      session[:current_entity] = @purchase_order.id
    end
    render_form
  end

  dyta(:purchase_order_lines, :conditions=>{:company_id=>['@current_company.id'], :order_id=>['@purchase_order.id']}) do |t|
    t.column :name, :through=>:product, :url=>{:action=>:products_display}
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :amount
    t.column :amount_with_taxes
    t.action :purchase_order_lines_update, :image=>:update
    t.action :purchase_order_line_delete,  :image=>:delete
    t.procedure :purchase_order_lines_create
  end

  def purchases_products
    @purchase_order = find_and_check(:purchase_order, params[:id])
    session[:current_purchase] = @purchase_order.id
    purchase_order_lines_list params
    @title = {:value=>@purchase_order.number}
  end

  def price_find
    product_id = params[:product_id]||(params[:purchase_order_line]||{})[:product_id]||session[:current_product].to_i
    product_id = 0 if product_id.blank?
    #raise Exception.new product_id.inspect
    session[:current_product] = product_id
    prices = Price.find(:all, :conditions=>{:product_id=>product_id.to_i})||[] ## +list_id, tax_id
    #raise Exception.new price.inspect
    #if prices == []
    #raise Exception.new "hjhjhj"
    # @tax = 0
    # @prices_amount = 0
    #else
    #raise Exception.new prices.inspect
    #price = Price.find(:first,:conditions=>{:product_id=>product_id.to_i})
    # raise Exception.new params[:purchase_order_line_product_id].inspect
    if Price.exists?(:id=>params[:purchase_order_line_product_id])
      @price_amount = Price.find_by_id(params[:purchase_order_line_product_id]).amount.to_i
    else
      @price_amount = 0 
    end
    # raise Exception.new @price_amount.inspect
    taxes = Tax.find(:all,:conditions=>{:company_id=>@current_company.id})||[]
    @tax = taxes.collect{|x| [x.name, x.id]}
   # @prices_amount = prices.collect{|x| [x.amount, x.id]} #price.amount.to_i
    #raise Exception.new params[:purchase_order_line][:product_id].inspect
    # @price_amount = Price.find_by_id()
    # @amount = Price.find(:first, :conditions=>{:product_id=>product_id.to_i})||[]
    #end
    #render :text=>options_for_select(@prices_amount,@tax) if request.xhr?
  end
  
  def purchase_order_lines_create
    @price = Price.new
    if request.post?
      @purchase_order_line = PurchaseOrderLine.new(params[:purchase_order_line])
      @purchase_order_line.company_id = @current_company.id
      @product = find_and_check(:product, params[:purchase_order_line][:product_id])
      @purchase_order_line.account_id = @product.account.id
      @purchase_order_line.order_id = session[:current_purchase]
      @purchase_order_line.unit_id = @product.unit.id
      tax = find_and_check(:tax, params[:price][:tax_id])
      # amount = find_and_check(:price, params[:price][:amount])
      amount = params[:price][:amount].to_i
      @purchase_order_line.amount = amount.to_i
      #raise Exception.new params[:purchase_order_line].inspect+tax.to_s+"       ff"+amount.to_s
      if !Price.exists?(:product_id=>@product, :list_id=>@purchase_order_line.order.list_id, :tax_id=>params[:price][:tax_id], :amount=>amount)
        #raise Exception.new exist.inspect
        amount_with_taxes = amount+(tax.amount*amount)
        Price.create!(:amount=>amount, :amount_with_taxes=>amount_with_taxes, :started_on=>Date.today,:product_id=>@product, :tax_id=>params[:price][:tax_id], :list_id=>@purchase_order_line.order.list_id,:company_id=>@current_company.id)
      end
      @purchase_order_line.amount_with_taxes = amount_with_taxes
      redirect_to :action=>:purchases_products, :id=>session[:current_purchase] if @purchase_order_line.save
    else
      @purchase_order_line = PurchaseOrderLine.new
      product = Product.find(:first, :conditions=>{:company_id=>@current_company.id})
      session[:current_product] = product.id.to_s
      #raise Exception.new session[:current_product].inspect
    end
    render_form
  end
  
  def purchase_order_lines_update
    @purchase_order_line = find_and_check(:purchase_order_line, params[:id])
    if request.post?
      params[:purchase_order_line][:company_id] = @current_company.id
      redirect_to :action=>:purchases_products, :id=>@purchase_order_line.order_id  if @purchase_order_line.update_attributes(params[:purchase_order_line])
    end
    render_form
  end

  dyta(:sale_orders, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :number, :url=>{:action=>:sales_products}
    t.column :name, :through=>:nature, :url=>{:action=>:sale_order_natures_display}
    t.column :full_name, :through=>:client, :url=>{:controller=>:relations, :action=>:entities_display}
    t.column :state
    t.column :amount
    t.column :amount_with_taxes
  end


  def sales
    sale_orders_list params
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
    contacts = Contact.find_all_by_entity_id_and_company_id(client_id, @current_company.id)||[]
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

  dyta(:sale_order_lines, :conditions=>{:company_id=>['@current_company.id'], :order_id=>['@sale_order.id']}, :empty=>true) do |t|
    t.column :name, :through=>:product
    t.column :name, :through=>:price_list
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :amount, :through=>:price
    t.column :amount
    t.column :amount_with_taxes
    t.action :sale_order_lines_update, :image=>:update
    t.action :sale_order_lines_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
    t.procedure :sale_order_lines_create
  end

  def sales_products
    @sale_order = find_and_check(:sale_order, params[:id])
    session[:current_sale_order] = @sale_order.id
    @entity = @sale_order.client
    sale_order_lines_list params
    if request.post?
      @sale_order.update_attribute(:state, 'D') if @sale_order.state == 'P'
      redirect_to :action=>:sales_deliveries, :id=>@sale_order.id
    end
    @title = {:client=>@entity.full_name, :sale_order=>@sale_order.number}
  end


  def sale_order_lines_create
    if request.post? 
      @sale_order_line = @current_company.sale_order_lines.find(:first, :conditions=>{:product_id=>params[:sale_order_line][:product_id], :order_id=>session[:current_sale_order]})
      if @sale_order_line
        @sale_order_line.quantity += params[:sale_order_line][:quantity].to_d
      else
        @sale_order_line = SaleOrderLine.new(params[:sale_order_line])
        @sale_order_line.company_id = @current_company.id
        @sale_order_line.order_id = session[:current_sale_order]
      end
      redirect_to_back if @sale_order_line.save
    else
      @sale_order_line = SaleOrderLine.new
    end
    render_form
  end

  def sale_order_lines_update
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


  dyta(:deliveries, :conditions=>{:company_id=>['@current_company.id'], :order_id=>['@sale_order.id']}, :empty=>true) do |t|
    t.column :amount
    t.column :amount_with_taxes
    t.column :shipped_on
    t.column :delivered_on
    t.column :comment
    t.procedure :deliveries_create
  end

  def sales_deliveries
    @sale_order = find_and_check(:sale_order, params[:id])
    session[:current_sale_order] = @sale_order.id
    deliveries_list params
  end



  def sales_invoices
  end

  def sales_payments
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
    t.action :stocks_locations_update, :image=>:update
    t.action :stocks_locations_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
    t.procedure :stocks_locations_create
  end

  dyta(:stock_moves, :conditions=>{:company_id=>['@current_company.id'], :location_id=>['@stock_location.id']}) do |t|
    t.column :name
    t.column :planned_on
    t.column :moved_on
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :name, :through=>:product
    t.column :comment
    t.action :stocks_moves_update, :image=>:update
    t.action :stocks_moves_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
    t.procedure :stocks_moves_create
  end
  
  def stocks_locations
    stock_locations_list params
  
    unless @stock_locations.size>0
      flash[:message] = tc('messages.need_stock_location_to_record_stock_moves')
      redirect_to :action=>:stocks_locations_create
      return
    end
  end

  def stocks_locations_display
    @stock_location = find_and_check(:stock_location, params[:id])
    session[:current_stock_location_id] = @stock_location.id
    stock_moves_list params
    @title = {:value=>@stock_location.name}
  end

  def stocks_locations_create
    if request.post? 
      @stock_location = StockLocation.new(params[:stock_location])
      @stock_location.company_id = @current_company.id
      redirect_to :action =>:stocks_locations_display, :id=>@stock_location.id if @stock_location.save
    else
      @stock_location = StockLocation.new
    end
    render_form
  end

  def stocks_locations_update
    @stock_location = find_and_check(:stock_location, params[:id])
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
      redirect_to :action =>:stocks_locations_display, :id=>@stock_move.location_id if @stock_move.save
    else
      @stock_move = StockMove.new
      @stock_move.planned_on = Date.today
    end
    render_form
  end

  def stocks_moves_update
    @stock_move = find_and_check(:stock_move, params[:id])
    if request.post?
      params[:stock_move][:company_id] = @current_company.id
      if @stock_move.update_attributes(params[:stock_move])
        redirect_to :action=>:stocks_locations_display, :id=>@stock_move.location_id
      end
    end
    render_form(:label=>@stock_move.name)
  end

  def stocks_moves_delete
    @stock_move = find_and_check(:stock_move, params[:id])
    if request.post? or request.delete?
      redirect_to :back if @stock_move.destroy
    end
  end

end
