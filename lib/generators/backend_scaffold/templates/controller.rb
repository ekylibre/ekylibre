class Backend::<%= controller_class_name -%>Controller < BackendController
  manage_restfully

  unroll_all

  list do |t|
    t.column :name, :url => true
  end

  # Displays the main page with the list of <%= plural_name -%>.
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => <%= class_name -%>.all }
      format.json { render :json => <%= class_name -%>.all }
    end
  end

  # Displays the page for one <%= singular_table_name -%>.
  def show
    return unless @<%= singular_table_name -%> = find_and_check
    respond_to do |format|
      format.html { t3e(@<%= singular_table_name -%>) }
      format.xml  { render :xml => @<%= singular_table_name -%> }
      format.json { render :json => @<%= singular_table_name -%> }
    end
  end

end
