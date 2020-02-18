require 'test_helper'

module AgroSystemes
  class WaterAnalysesExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = AgroSystemes::WaterAnalysesExchanger.build(fixture_files_path.join('imports', 'agro_systemes', 'water_analyses.csv')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
