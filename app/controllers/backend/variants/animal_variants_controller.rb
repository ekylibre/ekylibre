module Backend
  module Variants
    class AnimalVariantsController < Backend::ProductNatureVariantsController

      importable_from_nomenclature :product_nature_variants, model_name: "Variants::#{controller_name.classify}".constantize,
                                                             filters: { type: :animal }
    end
  end
end
