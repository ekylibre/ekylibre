module Backend
  module Variants
    class CropVariantsController < Backend::ProductNatureVariantsController

      importable_from_nomenclature :product_nature_variants, model_name: "Variants::#{controller_name.classify}".constantize,
                                                             filters: { type: :crop }
    end
  end
end
