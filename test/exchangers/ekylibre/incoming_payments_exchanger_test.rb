require 'test_helper'

module Ekylibre
  class IncomingPaymentsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      Ekylibre::IncomingPaymentsExchanger.import(fixture_files_path.join('imports', 'ekylibre', 'incoming_payments.csv'))
    end
  end
end
