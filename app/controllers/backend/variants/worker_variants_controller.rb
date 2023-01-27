module Backend
  module Variants
    class WorkerVariantsController < Backend::ProductNatureVariantsController
      importable_from_lexicon :master_variants, model_name: "Variants::#{controller_name.classify}".constantize,
                                                primary_key: :reference_name,
                                                filters: { of_families: :worker },
                                                notify: { success: :worker_has_been_imported }
    end
  end
end
