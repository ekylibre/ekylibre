module Backend
  module Variants
    module Articles
      class FertilizerArticlesController < Backend::Variants::ArticleVariantsController

        importable_from_lexicon :variants, model_name: "Variants::Articles::#{controller_name.classify}".constantize,
                                           filter_by_nature: 'article',
                                           filter_by_sub_nature: 'fertilizer'
      end
    end
  end
end
