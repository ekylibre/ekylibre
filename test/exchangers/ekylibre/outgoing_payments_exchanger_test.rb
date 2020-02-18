require 'test_helper'

module Ekylibre
  class OutgoingPaymentsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = Ekylibre::OutgoingPaymentsExchanger.build(fixture_files_path.join('imports', 'ekylibre', 'outgoing_payments.csv')).run
      assert result.success?, [result.message, result.exception]
    end
  end
end
