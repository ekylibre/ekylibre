class Backend::SettlementsController < BackendController
  manage_restfully

  unroll

  list do |t|
    t.column :name, :url => true
  end

  # Displays the main page with the list of settlements.
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => Settlement.all }
      format.json { render :json => Settlement.all }
    end
  end

  # Displays the page for one settlement.
  def show
    return unless @settlement = find_and_check
    respond_to do |format|
      format.html { t3e(@settlement) }
      format.xml  { render :xml => @settlement }
      format.json { render :json => @settlement }
    end
  end

end
