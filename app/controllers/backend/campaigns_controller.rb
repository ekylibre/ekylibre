class Backend::CampaignsController < BackendController
  manage_restfully

  unroll_all

  list do |t|
    t.column :name, :url => true
    t.column :closed
  end

  # Displays the main page with the list of campaigns.
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => Campaign.all }
      format.json { render :json => Campaign.all }
    end
  end

  # Displays the page for one campaign.
  def show
    return unless @campaign = find_and_check
    respond_to do |format|
      format.html { t3e(@campaign) }
      format.xml  { render :xml => @campaign }
      format.json { render :json => @campaign }
    end
  end

end
