module Backend
  module VariantTypes
    class CropTypesController < Backend::ProductNaturesController

      importable_from_nomenclature :product_natures, model_name: "VariantTypes::#{controller_name.classify}".constantize,
                                                     filters: { nature: :crop }
    end
  end
end
