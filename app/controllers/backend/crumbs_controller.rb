class Backend::CrumbsController < BackendController

  @actors = []

  def index
    # array of crumbs ready to be managed by VisualizationHelper
    @interventions_crumbs = []

    interventions = Crumb.interventions(current_user.id)
    interventions.each do |intervention|
      name = interventions.index(intervention)
      started_at = intervention.first.read_at
      stopped_at = intervention.last.read_at
      doer = User.find(intervention.first.user_id)

      intervention.each do |crumb|
        item =  {
                  name:         name,
                  read_at:      crumb.read_at,
                  nature:       crumb.nature,
                  shape:        crumb.geolocation,
                  started_at:   started_at,
                  stopped_at:   stopped_at,
                  doer:         doer,
                  crumb:        crumb
                }
        @interventions_crumbs << item
      end
    end
  end

end