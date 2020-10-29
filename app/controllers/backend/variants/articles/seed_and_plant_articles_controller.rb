module Backend
  module Variants
    module Articles
      class SeedAndPlantArticlesController < Backend::Variants::ArticleVariantsController

        importable_from_lexicon :variants, model_name: "Variants::Articles::#{controller_name.classify}".constantize,
                                           filter_by_nature: 'article',
                                           filter_by_sub_nature: 'seed_and_plant'
      end
    end
  end
end
