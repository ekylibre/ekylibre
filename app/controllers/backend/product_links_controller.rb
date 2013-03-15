class Backend::ProductLinksController < BackendController
  manage_restfully

  unroll_all

  list do |t|
    t.column :name, :url => true
  end

  # Displays the main page with the list of product_links
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => ProductLink.all }
      format.json { render :json => ProductLink.all }
    end
  end

  # Displays the page for one product_link
  def show
    return unless @product_link = find_and_check
    respond_to do |format|
      format.html { t3e(@product_link) }
      format.xml  { render :xml => @product_link }
      format.json { render :json => @product_link }
    end
  end

end
