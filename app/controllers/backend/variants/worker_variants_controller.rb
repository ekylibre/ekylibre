module Backend
  module Variants
    class WorkerVariantsController < Backend::ProductNatureVariantsController

      importable_from_nomenclature :product_nature_variants, model_name: "Variants::#{controller_name.classify}".constantize,
                                                             filters: { type: :worker }
    end
  end
end
