class ManagementController < ApplicationController

  def index
  end


  dyta(:products, :conditions=>:search_conditions) do |t|
    t.column :number
    t.column :name
    t.column :description
    t.column :active
    t.procedure :new_product, :action=>:products_create
  end

  dyta(:stock_locations, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :name, :through=>:establishment
    t.column :name, :through=>:parent
    t.procedure :stocks_locations_create
  end
  

  def products
    key = params[:key]
    key = params[:search][:keyword] if params[:search]
    #    raise Exception.new params.inspect if request.post?
    products_list({:attributes=>[:name, :description, :catalog_name, :catalog_description, :comment], :key=>key}.merge(params))
  end


  def products_display
    @product = find_and_check(:product, params[:id])
  end

  def products_create
    if request.post? 
      @product = Product.new(params[:product])
      @product.company_id = @current_company.id
      redirect_to :action =>:products_display, :id=>@product.id if @product.save
    else
      @product = Product.new
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

  
  def purchases
  end

  def stocks_locations
    stock_locations_list params
  end

  def stocks_locations_create
    if request.post? 
      @stock_location = StockLocation.new(params[:stock_location])
      @stock_location.company_id = @current_company.id
      redirect_to :action =>:stocks_locations, :id=>@stock_location.id if @stock_location.save
    else
      @stock_location = StockLocation.new
    end
    render_form
  end

  def stocks_locations_update
    @stock_location = find_and_check(:stock_location, params[:id])
    if request.post?
      if @stock_location.update_attributes(params[:stock_location])
        redirect_to :action=>:stock_locations_display, :id=>@stock_location.id
      end
    end
    render_form(:label=>@stock_location.name)
  end

  def stocks_locations_delete
    @stock_location = find_and_check(:stock_location, params[:id])
    if request.post? or request.delete?
      redirect_to :back if @stock_location.delete
    end
  end

end
