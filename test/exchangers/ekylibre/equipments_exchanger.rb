module Ekylibre
  class EquipmentsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      ActiveExchanger::Base.import(:ekylibre_equipments, fixture_files_path.join('imports', 'ekylibre_equipments.csv'))
    end
  end
end
