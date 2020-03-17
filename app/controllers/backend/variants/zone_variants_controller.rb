module Backend
  module Variants
    class ZoneVariantsController < Backend::ProductNatureVariantsController

      importable_from_lexicon :variants, model_name: "Variants::#{controller_name.classify}".constantize, filter_by_nature: 'zone'
    end
  end
end
