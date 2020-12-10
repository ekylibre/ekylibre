# frozen_string_literal: true

# TODO: remove it when costings are not saved in db,
# but calculated on the fly by psql
class UpdateInterventionCostingsJob < ApplicationJob
  queue_as :default

  def perform(interventions_ids)
    interventions = Intervention.where(id: interventions_ids)
    interventions.each(&:update_costing)
  end
end
