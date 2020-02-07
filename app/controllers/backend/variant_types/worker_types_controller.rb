module Backend
  module VariantTypes
    class WorkerTypesController < Backend::ProductNaturesController

      importable_from_lexicon :variant_natures, model_name: "VariantTypes::#{controller_name.classify}".constantize, filter_by_nature: 'worker'
    end
  end
end
