require 'test_helper'

module Ekylibre
  class MattersExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      Ekylibre::MattersExchanger.import(fixture_files_path.join('imports', 'ekylibre', 'matters.csv'))
    end
  end
end
