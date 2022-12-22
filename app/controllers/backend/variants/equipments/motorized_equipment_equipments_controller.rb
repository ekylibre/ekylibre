module Backend
  module Variants
    module Equipments
      class MotorizedEquipmentEquipmentsController < Backend::Variants::EquipmentVariantsController
        importable_from_lexicon :master_variants, model_name: "Variants::Equipments::#{controller_name.classify}".constantize,
                                                  primary_key: :reference_name,
                                                  filters: { of_families: :equipment, of_sub_families: :motorized_equipment },
                                                  notify: { success: :equipment_has_been_imported }
      end
    end
  end
end
