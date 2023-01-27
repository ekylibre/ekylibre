# frozen_string_literal: true

module Ekylibre
  class WorkersJsonExchanger < ActiveExchanger::Base
    category :human_resources
    vendor :ekylibre

    def import
      workers = JSON.parse(file.read)
      workers.each do |worker|
        entity = Entity.create!(
          first_name: worker['first_name'],
          last_name: worker['last_name'],
          nature: 'contact'
        )
        started_at = if (Time.zone.now - 1.year) < Entity.of_company.born_at
                       Entity.of_company.born_at
                     else
                       Time.zone.now - 1.year
                     end
        WorkerContract.import_from_lexicon(
          reference_name: worker['contract'],
          entity_id: entity.id,
          started_at: started_at
        )
      end
    end
  end
end
