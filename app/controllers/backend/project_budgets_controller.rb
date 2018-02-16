module Backend
  class ProjectBudgetsController < Backend::BaseController
    manage_restfully

    unroll

    list(order: :name) do |t|
      t.action :edit
      t.action :destroy
      t.column :name
      t.column :description
    end
  end
end
