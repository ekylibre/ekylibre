class Backend::MineralMattersController < BackendController
  manage_restfully

  unroll

  list do |t|
    t.column :name, :url => true
  end

  # Displays the main page with the list of mineral_matters.
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => MineralMatter.all }
      format.json { render :json => MineralMatter.all }
    end
  end

  # Displays the page for one mineral_matter.
  def show
    return unless @mineral_matter = find_and_check
    respond_to do |format|
      format.html { t3e(@mineral_matter) }
      format.xml  { render :xml => @mineral_matter }
      format.json { render :json => @mineral_matter }
    end
  end

end
