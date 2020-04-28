module Backend
  module VariantTypes
    class AnimalTypesController < Backend::ProductNaturesController

      importable_from_nomenclature :product_natures, model_name: "VariantTypes::#{controller_name.classify}".constantize,
                                                     filters: { nature: :animal }
    end
  end
end
