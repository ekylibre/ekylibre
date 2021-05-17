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
      if segment = AnalyticSegment.find_by(name: 'project_budgets')
        notify_warning(:fill_analytic_codes_of_your_segments.tl(segment: segment.name.text.downcase))
      end
      respond_to do |format|
        format.html
        format.xml  { render xml:  resource_model.all }
        format.json { render json: resource_model.all }
      end
    end
  end
end
