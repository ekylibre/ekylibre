class LinkCrumbsToInterventions < ActiveRecord::Migration
  def change
    change_column :crumbs, :accuracy, :decimal, precision: 19, scale: 4
    change_column_null :crumbs, :user_id, true
    add_reference :crumbs, :intervention_cast, index: true
  end
end
