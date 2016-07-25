require 'test_helper'

module CharentesAlliance
  class IncomingDeliveriesExchangerTest < ::ActiveExchanger::TestCase
    test 'import' do
      ::ActiveExchanger::Base.import(:charentes_alliance_incoming_deliveries, fixture_files_path.join('imports', 'charentes_alliance_incoming_deliveries.csv'))
    end
  end
end
