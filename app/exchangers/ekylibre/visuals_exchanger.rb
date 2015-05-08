class Ekylibre::VisualsExchanger < ActiveExchanger::Base

  def import
    w.count = 1
    # load background
    Ekylibre::CorporateIdentity::Visual.set_default_background(file)
    w.check_point
  end

end
