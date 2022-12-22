module Backend
  module Variants
    class ArticleVariantsController < Backend::ProductNatureVariantsController
      importable_from_lexicon :master_variants, model_name: "Variants::#{controller_name.classify}".constantize,
                                                primary_key: :reference_name,
                                                filters: { of_families: :article },
                                                notify: { success: :article_has_been_imported }
    end
  end
end
