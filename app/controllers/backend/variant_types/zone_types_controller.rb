module Backend
  module VariantTypes
    class ZoneTypesController < Backend::ProductNaturesController

      importable_from_nomenclature :product_natures, model_name: "VariantTypes::#{controller_name.classify}".constantize,
                                                     filters: { nature: :zone }
    end
  end
end
