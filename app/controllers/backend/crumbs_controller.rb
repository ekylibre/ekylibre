class Backend::CrumbsController < BackendController

  @actors = []

  def index
    # array of crumbs ready to be managed by VisualizationHelper
    @interventions_crumbs = []

    # production supports
    @production_supports = []

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
                  doer_id:      doer.id,
                  crumb_id:     crumb.id
                }
        @interventions_crumbs << item
        @production_supports << crumb.production_support unless @production_supports.include?(crumb.production_support)
      end
    end
  end

  def update
    crumb = Crumb.find(params[:id])
    if crumb_params[:previous_crumb_id]
      previous = Crumb.find(crumb_params[:previous_crumb_id])
      previous.update(nature: 'stop')
    end
    crumb.update(nature: crumb_params[:nature])
    redirect_to backend_crumbs_path
  end

  private
    def crumb_params
      params.permit(:nature, :previous_crumb_id)
    end

end