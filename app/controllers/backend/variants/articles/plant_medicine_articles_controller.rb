module Backend
  module Variants
    module Articles
      class PlantMedicineArticlesController < Backend::Variants::ArticleVariantsController

        importable_from_lexicon :registered_phytosanitary_products, model_name: "Variants::Articles::#{controller_name.classify}".constantize
      end
    end
  end
end
