class Backend::ProductAbilitiesController < BackendController
  manage_restfully

  unroll_all

  list do |t|
    t.column :name, :url => true
  end

  # Displays the main page with the list of product_abilities
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => ProductAbility.all }
      format.json { render :json => ProductAbility.all }
    end
  end

  # Displays the page for one product_ability
  def show
    return unless @product_ability = find_and_check
    respond_to do |format|
      format.html { t3e(@product_ability) }
      format.xml  { render :xml => @product_ability }
      format.json { render :json => @product_ability }
    end
  end

end
