module Backend
  module VariantCategories
    class ServiceCategoriesController < Backend::ProductNatureCategoriesController

      importable_from_nomenclature :product_nature_categories, model_name: "VariantCategories::#{controller_name.classify}".constantize,
                                                               filters: { type: :fee_and_service }
    end
  end
end
