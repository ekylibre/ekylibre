module Ekylibre
  class VisualsExchanger < ActiveExchanger::Base
    category :settings
    vendor :ekylibre

    def import
      w.count = 1
      # load background
      Ekylibre::CorporateIdentity::Visual.set_default_background(file)
      w.check_point
    end
  end
end
