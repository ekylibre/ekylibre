module Backend
  module VariantCategories
    class AnimalCategoriesController < Backend::ProductNatureCategoriesController

      importable_from_lexicon :variant_categories, model_name: "VariantCategories::#{controller_name.classify}".constantize, filter_by_nature: 'animal'
    end
  end
end
