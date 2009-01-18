class ManagementController < ApplicationController

  def index
  end

  dyta(:price_lists, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :active
    t.column :name, :through=>:currency
    t.column :count, :through=>:prices, :label=>'Nb Prix'
    t.column :comment
    t.action :price_lists_display, :image=>:show
    t.action :price_lists_update, :image=>:update
    t.action :price_lists_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
    t.procedure :price_lists_create
  end

  def price_lists
    price_lists_list params
  end

  def price_lists_display
    @price_list = find_and_check(:price_list, params[:id])    
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
    render_form(:label=>@price_list.name)
  end

  def price_lists_delete
    @price_list = find_and_check(:price_list, params[:id])
    if request.post? or request.delete?
      redirect_to :back if @price_list.delete
    end
  end

  dyta(:prices, :conditions=>{:company_id=>['@current_company.id'], :list_id=>['@price_list.id'], :deleted=>false}) do |t|
    t.column :name, :through=>:product
    t.column :amount
    t.column :amount_with_taxes
    t.action :prices_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
    t.procedure :prices_create
  end

  def prices_create
    if request.post? 
      @price = Price.new(params[:price])
      @price.company_id = @current_company.id
      redirect_to :action =>:prices if @price.save
    else
      if @current_company.available_products.size<=0
        flash[:message] = lc(:messages, :need_product_to_create_price)
        redirect_to :action=> :products_create
      end
      @price = Price.new
    end
    render_form    
  end





  dyta(:products, :conditions=>:search_conditions, :empty=>true) do |t|
    t.column :number
    t.column :code
    t.column :name
    t.column :description
    t.column :active
    t.action :products_display, :image=>:show
    t.action :products_update, :image=>:update
    t.action :products_delete, :image=>:delete, :method=>:post, :confirm=>:are_you_sure
    t.procedure :new_product, :action=>:products_create
  end

  def products
    @key = params[:key]||session[:product_key]
    session[:product_key] = @key
    products_list({:attributes=>[:id, :name, :description, :catalog_name, :catalog_description, :comment], :key=>@key}.merge(params))
  end

  def products_display
    @product = find_and_check(:product, params[:id])
  end

  def products_create
    if request.post? 
      @product = Product.new(params[:product])
      @product.company_id = @current_company.id
      redirect_to_back if @product.save
    else
      @product = Product.new
      @product.nature = Product.natures.first
      @product.supply_method = Product.supply_methods.first
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
    render_form(:label=>@product.name)
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




  def purchases
  end





  def sales
  end

  # Step 1
  def sales_new
    @step = 1
    @sale = SaleOrder.new
    session[:sales] = {}
    session[:sales][:nature]    = params[:nature]
    session[:sales][:client_id] = params[:client]
    session[:sales] = params[:sales] if params[:sales].is_a? Hash
    if session[:sales][:client_id]
      client = Entity.find_by_company_id_and_id(session[:sales][:client_id], @current_company.id)
      session[:sales].delete(:client_id) if client.nil?
    end
    if request.get?
      unless session[:sales][:nature].nil? or session[:sales][:client_id].nil?
        redirect_to :action=>:sales_general
      end
    end
  end

  # Step 2
  def sales_general
    @step = 2
  end

  # Step 3
  def sales_products
    @step = 3
  end

  # Step 4
  def sales_deliveries
    @step = 4
  end

  # Step 5
  def sales_invoices
    @step = 5
  end

  # Step 6
  def sales_payments
    @step = 6
  end

  # Step 7
  def sales_print
    @step = 7
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
  end

  def stocks_locations_display
    @stock_location = find_and_check(:stock_location, params[:id])
    session[:current_stock_location_id] = @stock_location.id
    stock_moves_list params
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
