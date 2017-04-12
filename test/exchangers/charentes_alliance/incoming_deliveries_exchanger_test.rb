require 'test_helper'

module CharentesAlliance
  class IncomingDeliveriesExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      CharentesAlliance::IncomingDeliveriesExchanger.import(fixture_files_path.join('imports', 'charentes_alliance', 'incoming_deliveries.csv'))
    end
  end
end
