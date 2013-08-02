class Backend::ProductNatureVariantsController < BackendController
  manage_restfully

  unroll_all

  list do |t|
    t.column :name, :url => true
    t.column :name, :through => :nature, :url => true
    t.column :unit_name
    t.column :frozen_indicators
    t.action :edit
    t.action :destroy, :if => "RECORD.destroyable\?"
  end

  list(:prices, :model => :product_prices, :conditions => ["variant_id = ? ",['session[:current_product_nature_variant_id]']], :order => "started_at DESC") do |t|
    t.column :pretax_amount
    t.column :started_at
    t.column :stopped_at
    t.column :name, :through => :supplier, :url => true
    t.column :name, :through => :listing, :url => true
  end

  list(:products, :model => :products, :conditions => ["variant_id = ? ",['session[:current_product_nature_variant_id]']], :order => "born_at DESC") do |t|
    t.column :name, :url => true
    t.column :identification_number
    t.column :born_at
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
    session[:current_product_nature_variant_id] = @product_nature_variant.id
    respond_to do |format|
      format.html { t3e(@product_nature_variant) }
      format.xml  { render :xml => @product_nature_variant }
      format.json { render :json => @product_nature_variant }
    end
  end

end
