module Interventions
  class HarvestInProgressQuery
    class << self
      # @param [ActiveRecord::Relation<Intervention>]
      # @param [Product] product
      # @param [Time] intervention_started_at
      # @return [Boolean]
      def call(relation, product, intervention_started_at)
        relation
          .joins(:targets)
          .where(intervention_parameters: { product_id: product.id })
          .where('started_at < ?', intervention_started_at)
          .select { |intervention| intervention.procedure.of_category?(:harvesting) }
      end
    end
  end
end
