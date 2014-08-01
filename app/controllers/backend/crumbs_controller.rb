class Backend::CrumbsController < BackendController

  @actors = []
  
  def index
    # array of crumbs ready to be managed by VisualizationHelper
    @interventions_crumbs = []
  
    # TODO: replace by the actual current user id! crumbs are personal data
    current_user_id = User.first 
    interventions = Crumb.interventions(current_user_id)
    interventions.each do |intervention|
      name = interventions.index(intervention)
      started_at = intervention.first.read_at
      stopped_at = intervention.last.read_at
      doer = User.find(current_user_id)
    
      intervention.each do |crumb|  
        item =  {
                  name:         name,
                  nature:       crumb.nature,
                  shape:        Charta::Geometry.new(crumb.geolocation).circle(crumb.accuracy/50000),
                  started_at:   started_at,
                  stopped_at:   stopped_at,
                  doer:         doer
                }
        @interventions_crumbs << item
      end 
    end
  end

end