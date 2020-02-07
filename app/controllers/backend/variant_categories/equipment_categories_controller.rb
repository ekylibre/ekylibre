module Backend
  module VariantCategories
    class EquipmentCategoriesController < Backend::ProductNatureCategoriesController

      importable_from_lexicon :variant_categories, model_name: "VariantCategories::#{controller_name.classify}".constantize, filter_by_nature: 'equipment'
    end
  end
end
