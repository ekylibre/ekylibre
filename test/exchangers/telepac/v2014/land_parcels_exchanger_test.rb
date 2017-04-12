require 'test_helper'

module Telepac
  module V2014
    class LandParcelsExchangerTest < ActiveExchanger::TestCase
      test 'import' do
        Telepac::V2014::LandParcelsExchanger.import(fixture_files_path.join('imports', 'telepac', 'v2014', 'land_parcels.zip'))
      end
    end
  end
end
