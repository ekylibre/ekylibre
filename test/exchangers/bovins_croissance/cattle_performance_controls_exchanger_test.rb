require 'test_helper'

module BovinsCroissance
  class CattlePerformanceControlsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = BovinsCroissance::CattlePerformanceControlsExchanger.build(fixture_files_path.join('imports', 'bovins_croissance', 'cattle_performance_controls.csv')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
