module Backend
  module Variants
    module Articles
      class FarmProductArticlesController < Backend::Variants::ArticleVariantsController
        importable_from_lexicon :master_variants, model_name: "Variants::Articles::#{controller_name.classify}".constantize,
                                                  primary_key: :reference_name,
                                                  filters: { of_families: :article, of_sub_families: :farm_product },
                                                  notify: { success: :article_has_been_imported }
      end
    end
  end
end
