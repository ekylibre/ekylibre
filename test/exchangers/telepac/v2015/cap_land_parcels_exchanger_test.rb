require 'test_helper'

module Telepac
  module V2015
    class CapLandParcelsExchangerTest < ActiveExchanger::TestCase
      test 'import' do
        Telepac::V2015::CapLandParcelsExchanger.import(fixture_files_path.join('imports', 'telepac', 'v2015', 'cap_land_parcels.zip'))
      end
    end
  end
end
