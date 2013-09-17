class Backend::ProductNatureVariantIndicatorDataController < BackendController
  manage_restfully

  unroll

  list do |t|
    t.column :name, :url => true
  end

  # Displays the main page with the list of product_nature_variant_indicator_data.
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => ProductNatureVariantIndicatorDatum.all }
      format.json { render :json => ProductNatureVariantIndicatorDatum.all }
    end
  end

  # Displays the page for one product_nature_variant_indicator_datum.
  def show
    return unless @product_nature_variant_indicator_datum = find_and_check
    respond_to do |format|
      format.html { t3e(@product_nature_variant_indicator_datum) }
      format.xml  { render :xml => @product_nature_variant_indicator_datum }
      format.json { render :json => @product_nature_variant_indicator_datum }
    end
  end

end
