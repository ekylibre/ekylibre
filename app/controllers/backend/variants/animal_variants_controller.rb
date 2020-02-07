module Backend
  module Variants
    class AnimalVariantsController < Backend::ProductNatureVariantsController

      importable_from_lexicon :variants, model_name: "Variants::#{controller_name.classify}".constantize, filter_by_nature: 'animal'
    end
  end
end
