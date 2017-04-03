require 'test_helper'

module Telepac
  module V2014
    class CapLandParcelsExchangerTest < ActiveExchanger::TestCase
      test 'import' do
        Telepac::V2014::CapLandParcelsExchanger.import(fixture_files_path.join('imports', 'telepac', 'v2014', 'cap_land_parcels.zip'))
      end
    end
  end
end
