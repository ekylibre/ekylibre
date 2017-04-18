require 'test_helper'

module Milklic
  class IndividualProductionExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      Milklic::IndividualProductionExchanger.import(fixture_files_path.join('imports', 'milklic', 'individual_production.csv'))
    end
  end
end
