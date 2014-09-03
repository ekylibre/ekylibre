class Backend::CrumbsController < BackendController
  manage_restfully only: [:update, :destroy]

  def index
    unless params[:worked_on].blank?
      @worked_on = params[:worked_on].to_date
    else
      @worked_on = current_user.unconverted_crumb_days.first
    end
  end

  # def update
  #   crumb = Crumb.find(params[:id])
  #   if crumb_params[:previous_crumb_id]
  #     previous = Crumb.find(crumb_params[:previous_crumb_id])
  #     previous.update(nature: 'stop')
  #   end
  #   crumb.update(nature: crumb_params[:nature])
  #   redirect_to backend_crumbs_path
  # end

  # def destroy
  #   crumb = Crumb.find(params[:id])
  #   if crumb.nature == 'start'
  #    crumb.intervention_path.map(&:destroy)
  #   else
  #     crumb.destroy
  #   end
  #   redirect_to backend_crumbs_path
  # end

  # Creates an intervention from crumb and redirects to an edit form for
  # the newly created intervention.
  def convert
    return unless crumb = find_and_check
    begin
      if intervention = crumb.convert!(params.slice(:procedure_name, :support_id, :actors_ids, :relevance, :limit, :history, :provisional, :max_arity))
        redirect_to edit_backend_intervention_path(intervention)
      elsif current_user.unconverted_crumb_days.any?
        redirect_to backend_crumbs_path(worked_on: params[:worked_on])
      else
        redirect_to backend_interventions_path
      end
    rescue Exception => e
      notify_error(e.message)
      redirect_to backend_crumbs_path
    end
  end

  # private

  # def crumb_params
  #   params.permit!
  # end

end
