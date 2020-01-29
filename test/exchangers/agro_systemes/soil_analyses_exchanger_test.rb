require 'test_helper'

module AgroSystemes
  class SoilAnalysesExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = AgroSystemes::SoilAnalysesExchanger.build(fixture_files_path.join('imports', 'agro_systemes', 'soil_analyses.csv')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
