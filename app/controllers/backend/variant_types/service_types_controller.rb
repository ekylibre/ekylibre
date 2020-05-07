module Backend
  module VariantTypes
    class ServiceTypesController < Backend::ProductNaturesController

      importable_from_nomenclature :product_natures, model_name: "VariantTypes::#{controller_name.classify}".constantize,
                                                     filters: { nature: :fee_and_service }
    end
  end
end
