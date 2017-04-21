require 'test_helper'

module AgroSystemes
  class WaterAnalysesExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      AgroSystemes::WaterAnalysesExchanger.import(fixture_files_path.join('imports', 'agro_systemes', 'water_analyses.csv'))
    end
  end
end
