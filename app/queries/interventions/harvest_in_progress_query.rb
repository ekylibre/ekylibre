module Planning
  module Interventions
    class HarvestInProgressQuery
      def self.call(relation, params)
        product = Product.find(params[:id])
        intervention_started_at = Time.parse(params[:intervention_started_at])

        relation
          .joins(:targets)
          .where(intervention_parameters: { product_id: product.id })
          .where('started_at < ?', intervention_started_at)
          .select { |intervention| intervention.procedure.of_category?(:crop_protection) }
      end
    end
  end
end