module FormObjects
  module Backend
    module Interventions
      class ValidateHarvestReentry < FormObjects::Base
        attr_accessor :date, :date_end, :targets, :ignore_intervention

        validates :date, :targets, presence: true

        def intervention
          if ignore_intervention.present?
            Intervention.find_by(id: ignore_intervention)
          else
            nil
          end
        end
      end
    end
  end
end