require 'test_helper'

module PanierLocal
  class IncomingPaymentsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      result = PanierLocal::IncomingPaymentsExchanger.build(fixture_files_path.join('imports', 'panier_local', 'panier_local_incoming_payments.csv')).run
      assert result.success?, [result.message, result.exception]
      assert_equal 45, IncomingPayment.count
    end
  end
end
