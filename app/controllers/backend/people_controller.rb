class Backend::PeopleController < BackendController
  manage_restfully

  unroll_all

  list do |t|
    t.column :name, :url => true
  end

  # Displays the main page with the list of people.
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => Person.all }
      format.json { render :json => Person.all }
    end
  end

  # Displays the page for one person.
  def show
    return unless @person = find_and_check
    respond_to do |format|
      format.html { t3e(@person) }
      format.xml  { render :xml => @person }
      format.json { render :json => @person }
    end
  end

end
