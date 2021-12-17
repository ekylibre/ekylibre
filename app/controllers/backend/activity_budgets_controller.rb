module Backend
  class ActivityBudgetsController < Backend::BaseController
    manage_restfully except: %i[index show], t3e: { activity_name: :activity_name, campaign_name: :campaign_name, name: :name }, creation_t3e: true

    unroll activity: :name, campaign: :name

    def self.itk_conditions
      code = search_conditions(entities: [:full_name], analyses: %i[reference_number number]) + " ||= []\n"
      code << "if params[:technical_itinerary_id].to_i > 0\n"
      code << "  c[0] << ' AND #{TechnicalItineraryInterventionTemplate.table_name}.technical_itinerary_id = ?'\n"
      code << "  c << params[:technical_itinerary_id].to_i\n"
      code << "end\n"
      code << "c\n"
      code.c
    end

    # list to show intervention template of current itk matching
    list(
      :intervention_templates,
      model: TechnicalItineraryInterventionTemplate,
      order: { position: :asc },
      conditions: itk_conditions
    ) do |t|
      t.column :human_day_between_intervention, label: :delay
      t.column :name, through: :intervention_template
      t.column :human_day_compare_to_planting, label: :day_compare_to_planting
      t.column :human_workflow, label: :workflow, through: :intervention_template
    end

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
      new_activity_budget.items.each do |budget_item|
        budget_item.update!(used_on: budget_item.used_on.change(year: budget_item.used_on.year + 1)) if budget_item.used_on.present?
      end
      if params[:edit]
        redirect_to action: :edit, id: new_activity_budget.id, redirect: params[:redirect]
      else
        redirect_to params[:redirect] || { controller: :activities, action: :show, id: @activity_budget.id }
      end
    end
  end
end
