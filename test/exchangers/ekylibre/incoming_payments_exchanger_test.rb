require 'test_helper'

module Ekylibre
  class IncomingPaymentsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = Ekylibre::IncomingPaymentsExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'incoming_payments.csv')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
