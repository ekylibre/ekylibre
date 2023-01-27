module Backend
  module Variants
    class ServiceVariantsController < Backend::ProductNatureVariantsController
      importable_from_lexicon :master_variants, model_name: "Variants::#{controller_name.classify}".constantize,
                                                primary_key: :reference_name,
                                                filters: { of_families: :service },
                                                notify: { success: :variant_has_been_imported }
    end
  end
end
