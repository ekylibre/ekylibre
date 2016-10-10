require 'test_helper'

module Ekylibre
  class ZonesExchangerTest < ::ActiveExchanger::TestCase
    test 'import' do
      ::ActiveExchanger::Base.import(:ekylibre_zones, fixture_files_path.join('imports', 'ekylibre_zones.csv'))
    end
  end
end
