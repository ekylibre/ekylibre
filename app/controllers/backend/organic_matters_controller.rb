class Backend::OrganicMattersController < BackendController
  manage_restfully

  unroll

  list do |t|
    t.column :name, :url => true
  end

  # Displays the main page with the list of organic_matters.
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => OrganicMatter.all }
      format.json { render :json => OrganicMatter.all }
    end
  end

  # Displays the page for one organic_matter.
  def show
    return unless @organic_matter = find_and_check
    respond_to do |format|
      format.html { t3e(@organic_matter) }
      format.xml  { render :xml => @organic_matter }
      format.json { render :json => @organic_matter }
    end
  end

end
