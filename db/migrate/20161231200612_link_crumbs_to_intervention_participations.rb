class LinkCrumbsToInterventionParticipations < ActiveRecord::Migration
  def change
    add_reference :crumbs, :intervention_participation, index: true, foreign_key: true
  end
end
