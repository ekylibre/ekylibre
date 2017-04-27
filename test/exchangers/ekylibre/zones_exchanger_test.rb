require 'test_helper'

module Ekylibre
  class ZonesExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      Ekylibre::ZonesExchanger.import(fixture_files_path.join('imports', 'ekylibre', 'zones.csv'))
    end
  end
end
