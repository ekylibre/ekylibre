require 'test_helper'

module Synel
  class InventoryExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      Synel::InventoryExchanger.import(fixture_files_path.join('imports', 'synel', 'inventory.csv'))
    end
  end
end
