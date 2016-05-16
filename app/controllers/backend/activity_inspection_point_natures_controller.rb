module Backend
  class ActivityInspectionPointNaturesController < Backend::BaseController
    autocomplete_for :name
  end
end
