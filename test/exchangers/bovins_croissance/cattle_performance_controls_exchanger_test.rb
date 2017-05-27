require 'test_helper'

module BovinsCroissance
  class CattlePerformanceControlsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      BovinsCroissance::CattlePerformanceControlsExchanger.import(fixture_files_path.join('imports', 'bovins_croissance', 'cattle_performance_controls.csv'))
    end
  end
end
