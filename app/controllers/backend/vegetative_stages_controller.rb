module Backend
  class VegetativeStagesController < Backend::BaseController
    unroll :label, order: :bbch_number
  end
end
