require 'test_helper'

module Synel
  class InventoryExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = Synel::InventoryExchanger.build(fixture_files_path.join('imports', 'synel', 'inventory.csv')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
