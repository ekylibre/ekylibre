require 'test_helper'

module PanierLocal
  class IncomingPaymentsExchangerTest < ActiveExchanger::TestCase
    test 'import' do
      PanierLocal::IncomingPaymentsExchanger.import(fixture_files_path.join('imports', 'panier_local', 'panier_local_incoming_payments.csv'))
      assert_equal 45, IncomingPayment.count
    end
  end
end
