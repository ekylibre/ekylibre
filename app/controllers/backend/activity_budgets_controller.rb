module Backend
  class ActivityBudgetsController < Backend::BaseController
    manage_restfully except: %i[index show], t3e: { activity_name: :activity_name, campaign_name: :campaign_name, name: :name }, creation_t3e: true

    unroll activity: :name, campaign: :name

    # No index for budgets
    def index
      redirect_to controller: :activities, action: :index
    end

    def show
      @activity_budget = find_and_check
      return unless @activity_budget
      redirect_to controller: :activities, action: :show, id: @activity_budget.activity_id
    end

    def duplicate
      @activity_budget = find_and_check
      return unless @activity_budget
      activity = Activity.find_by(id: params[:activity_id])
      campaign = Campaign.find_by(id: params[:campaign_id])
      new_activity_budget = @activity_budget.duplicate!(activity, campaign)
      if params[:edit]
        redirect_to action: :edit, id: new_activity_budget.id, redirect: params[:redirect]
      else
        redirect_to params[:redirect] || { controller: :activities, action: :show, id: @activity_budget.id }
      end
    end
  end
end
