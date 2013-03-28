class Backend::ProductPricesController < BackendController
  manage_restfully

  unroll_all

  list do |t|
    t.column :name, :url => true
  end

  # Displays the main page with the list of product_prices.
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => ProductPrice.all }
      format.json { render :json => ProductPrice.all }
    end
  end

  # Displays the page for one product_price.
  def show
    return unless @product_price = find_and_check
    respond_to do |format|
      format.html { t3e(@product_price) }
      format.xml  { render :xml => @product_price }
      format.json { render :json => @product_price }
    end
  end

end
