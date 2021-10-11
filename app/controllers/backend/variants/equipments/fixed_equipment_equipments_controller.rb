module Backend
  module Variants
    module Equipments
      class FixedEquipmentEquipmentsController < Backend::Variants::EquipmentVariantsController
        importable_from_lexicon :master_variants, model_name: "Variants::Equipments::#{controller_name.classify}".constantize,
                                                  primary_key: :reference_name,
                                                  filters: { of_families: :equipment, of_sub_families: :fixed_equipment }
      end
    end
  end
end
