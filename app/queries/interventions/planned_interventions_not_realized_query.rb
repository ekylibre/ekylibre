# frozen_string_literal: true

module Interventions
  class PlannedInterventionsNotRealizedQuery
    def self.call(relation, day, params)
      beginning_of_week = day
                          .beginning_of_week
                          .beginning_of_day

      end_of_week = day
                    .end_of_week
                    .end_of_day

      interventions_with_request = Interventions::WithInterventionRequestQuery.call(::Intervention)

      result = relation
                 .where(nature: :request)
                 .where('interventions.id NOT IN (?)', interventions_with_request.map(&:request_intervention_id))
                 .between(beginning_of_week, end_of_week)
                 .where.not(state: :rejected)

      if params[:land_parcel_id].present?
        result = result
                 .joins(:activity_productions)
                 .where(activity_productions: { support_id: params[:land_parcel_id] })
      end

      if params[:procedure_name].present?
        result = result.where(procedure_name: params[:procedure_name])
      end

      if params[:activity_id].present?
        result = result.of_activity(Activity.find(params[:activity_id]))
      end

      if params[:worker_id].present?
        result = result
                 .joins(:doers)
                 .where(intervention_parameters: { product_id: params[:worker_id] })
      end

      if params[:equipment_id].present?
        result = result
                 .joins(:tools)
                 .where(intervention_parameters: { product_id: params[:equipment_id] })
      end

      result
    end
  end
end
