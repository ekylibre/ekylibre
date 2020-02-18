module Backend
  module Variants
    class WorkerVariantsController < Backend::ProductNatureVariantsController

      importable_from_lexicon :variants, model_name: "Variants::#{controller_name.classify}".constantize, filter_by_nature: 'worker'
    end
  end
end
