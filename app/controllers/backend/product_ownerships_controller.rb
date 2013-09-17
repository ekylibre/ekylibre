class Backend::ProductOwnershipsController < BackendController
  manage_restfully

  unroll

  list do |t|
    t.column :name, :url => true
  end

  # Displays the main page with the list of product_ownerships.
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => ProductOwnership.all }
      format.json { render :json => ProductOwnership.all }
    end
  end

  # Displays the page for one product_ownership.
  def show
    return unless @product_ownership = find_and_check
    respond_to do |format|
      format.html { t3e(@product_ownership) }
      format.xml  { render :xml => @product_ownership }
      format.json { render :json => @product_ownership }
    end
  end

end
