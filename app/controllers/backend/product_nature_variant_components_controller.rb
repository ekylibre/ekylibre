module Backend
  class ProductNatureVariantComponentsController < Backend::BaseController
    autocomplete_for :name
    unroll
   end
end
