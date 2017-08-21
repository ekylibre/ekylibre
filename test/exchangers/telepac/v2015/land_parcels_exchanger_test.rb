require 'test_helper'

module Telepac
  module V2015
    class LandParcelsExchangerTest < ActiveExchanger::TestCase
      test 'import' do
        Telepac::V2015::LandParcelsExchanger.import(fixture_files_path.join('imports', 'telepac', 'v2015', 'land_parcels.zip'))
      end
    end
  end
end
