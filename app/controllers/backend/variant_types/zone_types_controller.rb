module Backend
  module VariantTypes
    class ZoneTypesController < Backend::ProductNaturesController

      importable_from_lexicon :variant_natures, model_name: "VariantTypes::#{controller_name.classify}".constantize, filter_by_nature: 'zone'
    end
  end
end
