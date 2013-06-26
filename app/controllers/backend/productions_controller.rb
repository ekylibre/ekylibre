class Backend::ProductionsController < BackendController
  
  manage_restfully

  unroll_all


  # management -> sales_conditions
  def self.productions_conditions
    code = ""
    code = search_conditions(:production, :productions => [:state], :activities =>[:name], :product_natures =>[:name]) + "||=[]\n"
    code << "unless session[:production_state].blank?\n"
    code << "  if session[:production_state] == 'all'\n"
    code << "    c[0] += \" AND state IN ('draft', 'validated', 'aborted', 'started')\"\n"
    code << "  end\n "
    code << "  if session[:production_campaign_id] > 0\n"
    code << "    c[0] += \" AND \#{Campaign.table_name}.id = ?\"\n"
    code << "    c << session[:production_campaign_id]\n"
    code << "  end\n"
    code << "  if session[:production_state].present? and session[:production_state] != 'all'\n"
    code << "    c[0] += \" AND state = ?\"\n"
    code << "    c << session[:production_state]\n"
    code << "  end\n"
    code << "  if session[:production_product_nature_id] > 0\n"
    code << "    c[0] += \" AND \#{ProductNature.table_name}.id = ?\"\n"
    code << "    c << session[:production_product_nature_id]\n"
    code << "  end\n"
    code << "end\n "
    code << "c\n "
    code
  end



  list(:conditions => productions_conditions, :joins => [:activity,:product_nature,:campaign]) do |t|
    t.column :name, :url => true
    t.column :name,:through => :activity, :url => true
    #t.column :name,:through => :campaign, :url => true
    #t.column :name,:through => :product_nature, :url => true
    t.column :name,:through => :storage, :url => true
    t.column :state_label
    t.action :edit, :if => 'RECORD.draft? '
    #t.action :print, :if => 'RECORD.validated? '
    t.action :destroy, :if => 'RECORD.aborted? '

  end

  # Displays the main page with the list of activity_watchings.
  def index
    session[:production_state] = params[:s] ||="all"
    session[:production_key] = params[:q]
    session[:production_product_nature_id] = params[:product_nature_id].to_i
    session[:production_campaign_id] = params[:campaign_id].to_i
    respond_to do |format|
      format.html
      format.xml  { render :xml => Production.all }
      format.json { render :json => Production.all }
    end
  end

  # Displays the page for one activity_watching.
  def show
    return unless @production = find_and_check
    respond_to do |format|
      format.html { t3e(@production) }
      format.xml  { render :xml => @production }
      format.json { render :json => @production }
    end
  end

end
