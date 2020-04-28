module Backend
  module VariantCategories
    class EquipmentCategoriesController < Backend::ProductNatureCategoriesController

      importable_from_nomenclature :product_nature_categories, model_name: "VariantCategories::#{controller_name.classify}".constantize,
                                                               filters: { type: :equipment }
    end
  end
end
