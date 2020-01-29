require 'test_helper'

module Ekylibre
  class MattersExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = Ekylibre::MattersExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'matters.csv')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
