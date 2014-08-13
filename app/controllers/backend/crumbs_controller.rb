class Backend::CrumbsController < BackendController

  def index
    # days
    @interventions_dates = Crumb.interventions_dates(current_user)
    date = crumb_params[:intervention_date] || @interventions_dates.first

    # array of crumbs ready to be managed by VisualizationHelper
    @interventions_crumbs = []

    crumb_ids = []

    interventions = []
    interventions = Crumb.of_date(date.to_date).interventions(current_user) if date.present?
    @production_supports = []
    @production_supports = Crumb.production_supports(interventions.flatten) if interventions.present?
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

  def destroy
    crumb = Crumb.find(params[:id])
    if crumb.nature == 'start'
     crumb.intervention.map(&:destroy)
    else
      crumb.destroy
    end
    redirect_to backend_crumbs_path
  end

  # creates an intervention from crumb and redirects to an edit form for
  # the newly created intervention.
  def convert
    crumb = Crumb.find(params[:id])
    intervention = crumb.convert(crumb_params)
    if intervention.present?
      redirect_to edit_backend_intervention_path(intervention)
    else
      redirect_to backend_crumbs_path
    end
  end

  private
    def crumb_params
      params.permit!
    end

end