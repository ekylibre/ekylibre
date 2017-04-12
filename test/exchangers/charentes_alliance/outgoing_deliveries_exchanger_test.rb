require 'test_helper'

module CharentesAlliance
  class OutgoingDeliveriesExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      CharentesAlliance::OutgoingDeliveriesExchanger.import(fixture_files_path.join('imports', 'charentes_alliance', 'outgoing_deliveries.zip'))
    end
  end
end
