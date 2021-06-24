module Backend
  class ProjectBudgetsController < Backend::BaseController
    manage_restfully except: :index

    unroll

    list(order: :name) do |t|
      t.action :edit
      t.action :destroy
      t.column :name
      t.column :description
      t.column :isacompta_analytic_code, hidden: AnalyticSegment.where(name: 'project_budgets').none?
    end

    def index
      missing_code_count = ProjectBudget.where("isacompta_analytic_code IS NULL OR isacompta_analytic_code = ''").count
      segment = AnalyticSegment.find_by(name: 'project_budgets')
      if segment.presence && missing_code_count > 0
        notify_warning :fill_analytic_codes_of_your_activities.tl(segment: segment.name.text.downcase, missing_code_count: missing_code_count)
      end
      respond_to do |format|
        format.html
        format.xml  { render xml:  resource_model.all }
        format.json { render json: resource_model.all }
      end
    end
  end
end
