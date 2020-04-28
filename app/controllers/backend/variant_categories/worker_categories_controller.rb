module Backend
  module VariantCategories
    class WorkerCategoriesController < Backend::ProductNatureCategoriesController

      importable_from_nomenclature :product_nature_categories, model_name: "VariantCategories::#{controller_name.classify}".constantize,
                                                               filters: { type: :worker }
    end
  end
end
