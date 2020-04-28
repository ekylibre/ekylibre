module Backend
  module VariantTypes
    class ArticleTypesController < Backend::ProductNaturesController

      importable_from_nomenclature :product_natures, model_name: "VariantTypes::#{controller_name.classify}".constantize,
                                                     filters: { nature: :article }
    end
  end
end
