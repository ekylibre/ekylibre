require 'test_helper'

module Ekylibre
  class VariantsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = Ekylibre::VariantsExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'variants.ods')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
