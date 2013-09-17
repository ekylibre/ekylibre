class Backend::OperationTasksController < BackendController
  manage_restfully

  unroll

  list do |t|
    t.column :name, :url => true
  end

  # Displays the main page with the list of operation_tasks
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => OperationTask.all }
      format.json { render :json => OperationTask.all }
    end
  end

  # Displays the page for one operation_task
  def show
    return unless @operation_task = find_and_check
    respond_to do |format|
      format.html { t3e(@operation_task) }
      format.xml  { render :xml => @operation_task }
      format.json { render :json => @operation_task }
    end
  end

end
