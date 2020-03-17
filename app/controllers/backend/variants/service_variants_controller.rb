module Backend
  module Variants
    class ServiceVariantsController < Backend::ProductNatureVariantsController

      importable_from_lexicon :variants, model_name: "Variants::#{controller_name.classify}".constantize, filter_by_nature: 'fee_and_service'
    end
  end
end
