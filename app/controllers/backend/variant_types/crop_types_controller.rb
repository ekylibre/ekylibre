module Backend
  module VariantTypes
    class CropTypesController < Backend::ProductNaturesController
      importable_from_lexicon :master_variant_natures, model_name: "VariantTypes::#{controller_name.classify}".constantize,
                                                       primary_key: :reference_name,
                                                       filters: { of_families: :crop }
    end
  end
end
