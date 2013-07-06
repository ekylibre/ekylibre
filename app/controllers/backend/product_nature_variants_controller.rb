class Backend::ProductNatureVariantsController < BackendController
  manage_restfully

  unroll_all

  list do |t|
    t.column :name, :url => true
  end

  # Displays the main page with the list of product_nature_variants.
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => ProductNatureVariant.all }
      format.json { render :json => ProductNatureVariant.all }
    end
  end

  # Displays the page for one product_nature_variant.
  def show
    return unless @product_nature_variant = find_and_check
    respond_to do |format|
      format.html { t3e(@product_nature_variant) }
      format.xml  { render :xml => @product_nature_variant }
      format.json { render :json => @product_nature_variant }
    end
  end

end
