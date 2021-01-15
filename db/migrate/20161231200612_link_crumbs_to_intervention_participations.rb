class LinkCrumbsToInterventionParticipations < ActiveRecord::Migration[4.2]
  def change
    add_reference :crumbs, :intervention_participation, index: true, foreign_key: true
  end
end
