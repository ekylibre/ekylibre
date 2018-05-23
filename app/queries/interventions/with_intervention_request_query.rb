module Interventions
  class WithInterventionRequestQuery
    def self.call(relation)
      relation
        .where(nature: :record)
        .where.not(request_intervention: nil)
    end
  end
end
