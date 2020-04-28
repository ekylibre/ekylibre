module Backend
  module Variants
    module Articles
      class FertilizerArticlesController < Backend::Variants::ArticleVariantsController

        importable_from_nomenclature :product_nature_variants, model_name: "Variants::Articles::#{controller_name.classify}".constantize,
                                                               filters: { type: :article, sub_type: :fertilizer }
      end
    end
  end
end
