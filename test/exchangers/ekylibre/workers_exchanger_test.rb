require 'test_helper'

module Ekylibre
  class WorkersExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = Ekylibre::WorkersExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'workers.csv')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
