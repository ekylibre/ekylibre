class Backend::AnimalGroupsController < BackendController
  manage_restfully

  unroll_all

  list do |t|
    t.column :name, :url => true
  end

  # Displays the main page with the list of animal_groups.
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => AnimalGroup.all }
      format.json { render :json => AnimalGroup.all }
    end
  end

  # Displays the page for one animal_group.
  def show
    return unless @animal_group = find_and_check
    respond_to do |format|
      format.html { t3e(@animal_group) }
      format.xml  { render :xml => @animal_group }
      format.json { render :json => @animal_group }
    end
  end

end
