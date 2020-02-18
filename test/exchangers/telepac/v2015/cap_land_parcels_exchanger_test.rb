require 'test_helper'

module Telepac
  module V2015
    class CapLandParcelsExchangerTest < ActiveExchanger::TestCase
      test 'import' do
        result = Telepac::V2015::CapLandParcelsExchanger.build(fixture_files_path.join('imports', 'telepac', 'v2015', 'cap_land_parcels.zip')).run
        assert result.success?, [result.message, result.exception]
      end
    end
  end
end
