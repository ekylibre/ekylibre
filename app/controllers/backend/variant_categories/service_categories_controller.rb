module Backend
  module VariantCategories
    class ServiceCategoriesController < Backend::ProductNatureCategoriesController

      importable_from_lexicon :variant_categories, model_name: "VariantCategories::#{controller_name.classify}".constantize, filter_by_nature: 'fee_and_service'
    end
  end
end
