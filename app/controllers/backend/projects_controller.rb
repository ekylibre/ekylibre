module Backend
  class ProjectsController < Backend::BaseController
    manage_restfully

    unroll

    # params:
    #   :q Text search
    #   :s State search
    #   :period Two Dates with _ separator
    #   :variant_id
    def self.list_conditions
      code = ''
      code = search_conditions(projects: %i[name comment]) + " ||= []\n"
      code << "  if params[:team_id].to_i > 0\n"
      code << "    c[0] << \" AND \#{Team.table_name}.id = ?\"\n"
      code << "    c << params[:team_id].to_i\n"
      code << "  end\n"
      code << "c\n"
      code.c
    end

    list(conditions: list_conditions, joins: %i[team]) do |t|
      t.action :edit, if: :updateable?
      t.action :destroy, if: :destroyable?
      t.column :name, url: true
      t.column :work_number
      t.column :nature
      t.column :responsible, url: true
      t.column :activity, url: true
      t.column :team, url: true
      t.column :started_on
      t.column :stopped_on
      t.column :forecast_duration
      t.column :real_duration
      t.column :closed
    end

    list :tasks, model: :project_tasks, conditions: { project_id: 'params[:id]'.c } do |t|
      t.action :edit, if: :updateable?
      t.action :destroy, if: :destroyable?
      t.column :work_number
      t.column :name, url: true
      t.column :responsible, url: true
      t.column :started_on
      t.column :stopped_on
      t.column :forecast_duration
      t.column :forecast_duration_unit
      t.column :real_duration
      t.column :sale_contract_item # , on_select: :sum
      t.column :billing_method, hidden: true
      # t.column :sale_contract_item, index: true, hidden: true
    end
  end
end
