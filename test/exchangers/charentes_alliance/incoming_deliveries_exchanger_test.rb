require 'test_helper'

module CharentesAlliance
  class IncomingDeliveriesExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = CharentesAlliance::IncomingDeliveriesExchanger.build(fixture_files_path.join('imports', 'charentes_alliance', 'incoming_deliveries.csv')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
