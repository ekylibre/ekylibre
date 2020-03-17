module Backend
  module VariantTypes
    class ServiceTypesController < Backend::ProductNaturesController

      importable_from_lexicon :variant_natures, model_name: "VariantTypes::#{controller_name.classify}".constantize, filter_by_nature: 'fee_and_service'
    end
  end
end
