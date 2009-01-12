class ManagementController < ApplicationController

  def index
  end


  dyta(:products, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :number
    t.column :name
    t.column :active
  end

  def products
#    products_list params


  end

  def products_display
    @product = Product.find_by_id_and_company_id(params[:id], @current_company.id)
    if @product.blank?
      flash[:error] = lc(:unavailable_product) 
      redirect_to :products
    end
  end


  def products_create
    @units = @current_company.units.find(:all, :order=>:label)
    @shelves = @current_company.shelves.find(:all, :order=>:name)
    @accounts = @current_company.accounts.find(:all, :conditions=>{:deleted=>false}, :order=>:number)
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
  end

  def products_delete
  end


  def products_search
    if request.post?
      if request.xhr?
      end
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

  def stocks
  end

end
