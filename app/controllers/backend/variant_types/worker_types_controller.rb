module Backend
  module VariantTypes
    class WorkerTypesController < Backend::ProductNaturesController

      importable_from_nomenclature :product_natures, model_name: "VariantTypes::#{controller_name.classify}".constantize,
                                                     filters: { nature: :worker }
    end
  end
end
