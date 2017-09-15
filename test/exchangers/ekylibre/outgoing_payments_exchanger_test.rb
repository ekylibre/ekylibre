require 'test_helper'

module Ekylibre
  class OutgoingPaymentsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      Ekylibre::OutgoingPaymentsExchanger.import(fixture_files_path.join('imports', 'ekylibre', 'outgoing_payments.csv'))
    end
  end
end
