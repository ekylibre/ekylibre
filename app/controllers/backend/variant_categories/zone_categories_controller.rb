module Backend
  module VariantCategories
    class ZoneCategoriesController < Backend::ProductNatureCategoriesController
      importable_from_lexicon :master_variant_categories, model_name: "VariantCategories::#{controller_name.classify}".constantize,
                                                          primary_key: :reference_name,
                                                          filters: { of_families: :zone }
    end
  end
end
