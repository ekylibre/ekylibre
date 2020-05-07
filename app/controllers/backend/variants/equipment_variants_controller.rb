module Backend
  module Variants
    class EquipmentVariantsController < Backend::ProductNatureVariantsController

      importable_from_nomenclature :product_nature_variants, model_name: "Variants::#{controller_name.classify}".constantize,
                                                             filters: { type: :equipment }
    end
  end
end
