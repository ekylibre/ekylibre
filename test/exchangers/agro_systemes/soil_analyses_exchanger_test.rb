require 'test_helper'

module AgroSystemes
  class SoilAnalysesExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      AgroSystemes::SoilAnalysesExchanger.import(fixture_files_path.join('imports', 'agro_systemes', 'soil_analyses.csv'))
    end
  end
end
