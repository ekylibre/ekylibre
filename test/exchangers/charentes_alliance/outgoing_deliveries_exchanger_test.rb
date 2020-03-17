require 'test_helper'

module CharentesAlliance
  class OutgoingDeliveriesExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = CharentesAlliance::OutgoingDeliveriesExchanger.build(fixture_files_path.join('imports', 'charentes_alliance', 'outgoing_deliveries.zip')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
