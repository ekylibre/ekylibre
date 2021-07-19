module Backend
  module VariantTypes
    class EquipmentTypesController < Backend::ProductNaturesController
      importable_from_lexicon :master_variant_natures, model_name: "VariantTypes::#{controller_name.classify}".constantize,
                                                       primary_key: :reference_name,
                                                       filters: { of_families: :equipment }
    end
  end
end
