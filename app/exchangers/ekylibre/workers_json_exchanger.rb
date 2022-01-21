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
        WorkerContract.import_from_lexicon(
          reference_name: worker['contract'],
          entity_id: entity.id,
          started_at: Time.now
        )
        Worker.create!(
          person: entity,
          name: entity.full_name,
          variant: ProductNatureVariant.import_from_lexicon(worker['type'])
        )
      end
    end
  end
end
