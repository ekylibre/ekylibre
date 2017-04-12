require 'test_helper'

module Ekylibre
  class VariantsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      Ekylibre::VariantsExchanger.import(fixture_files_path.join('imports', 'ekylibre', 'variants.ods'))
    end
  end
end
