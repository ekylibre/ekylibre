module Backend
  module Variants
    class ServiceVariantsController < Backend::ProductNatureVariantsController

      importable_from_nomenclature :product_nature_variants, model_name: "Variants::#{controller_name.classify}".constantize,
                                                             filters: { type: :fee_and_service }
    end
  end
end
