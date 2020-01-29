require 'test_helper'

module Milklic
  class IndividualProductionExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = Milklic::IndividualProductionExchanger.build(fixture_files_path.join('imports', 'milklic', 'individual_production.csv')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
