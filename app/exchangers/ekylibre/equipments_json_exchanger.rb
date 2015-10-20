class Ekylibre::EquipmentsJsonExchanger < ActiveExchanger::Base
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
      variant = ProductNatureVariant.import_from_nomenclature(equipment['type'])
      storage = Product.find_by(name: equipment['zone'])
      Equipment.create!(equipment.slice('name').merge(initial_container: storage, default_storage: storage, variant: variant))
    end
  end
end
