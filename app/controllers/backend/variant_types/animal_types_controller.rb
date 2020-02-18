module Backend
  module VariantTypes
    class AnimalTypesController < Backend::ProductNaturesController

      importable_from_lexicon :variant_natures, model_name: "VariantTypes::#{controller_name.classify}".constantize, filter_by_nature: 'animal'
    end
  end
end
