# frozen_string_literal: true

module Ekylibre
  class EquipmentsJsonExchanger < ActiveExchanger::Base
    category :plant_farming
    vendor :ekylibre

    # def check
    #   valid = true
    #   clusters = JSON.parse(file.read).deep_symbolize_keys
    #   unless clusters[:type] == 'FeatureCollection'
    #     w.error 'Invalid format'
    #     valid = false
    #   end
    #   valid
    # end

    def import
      equipments = JSON.parse(file.read)
      equipments.each do |equipment|
        variant = ProductNatureVariant.import_from_lexicon(equipment['type'])
        storage = Product.find_by(name: equipment['zone'])
        attributes = { initial_container: storage,
                       default_storage: storage,
                       initial_born_at: Entity.of_company.born_at,
                       variant: variant }
        Equipment.create!(equipment.slice('name').merge(attributes))
      end
    end
  end
end
