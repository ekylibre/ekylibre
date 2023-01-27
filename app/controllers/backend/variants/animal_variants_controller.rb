module Backend
  module Variants
    class AnimalVariantsController < Backend::ProductNatureVariantsController
      importable_from_lexicon :master_variants, model_name: "Variants::#{controller_name.classify}".constantize,
                                                primary_key: :reference_name,
                                                filters: { of_families: :animal },
                                                notify: { success: :animal_has_been_imported }
    end
  end
end
