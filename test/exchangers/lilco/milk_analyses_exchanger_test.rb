require 'test_helper'

module Lilco
  class MilkAnalysesExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      Lilco::MilkAnalysesExchanger.import(fixture_files_path.join('imports', 'lilco', 'milk_analyses.csv'))
    end
  end
end
