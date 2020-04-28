module Backend
  module VariantTypes
    class EquipmentTypesController < Backend::ProductNaturesController

      importable_from_nomenclature :product_natures, model_name: "VariantTypes::#{controller_name.classify}".constantize,
                                                     filters: { nature: :equipment }
    end
  end
end
