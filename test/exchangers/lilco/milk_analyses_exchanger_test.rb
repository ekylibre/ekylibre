require 'test_helper'

module Lilco
  class MilkAnalysesExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = Lilco::MilkAnalysesExchanger.build(fixture_files_path.join('imports', 'lilco', 'milk_analyses.csv')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
