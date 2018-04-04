# This migration comes from planning_engine (originally 20180330120700)
class AddDataToInterventionProposalTable < ActiveRecord::Migration
  I18n.locale = :fra
  def change
    ActivityProduction.where.not(technical_itinerary: nil).each do |activity_production|
      activity_production.save
    end
  end
end
