require 'test_helper'

module PanierLocal
  module IncomingPaymentsTest
    class IncomingPaymentsExchangerTest < ActiveExchanger::TestCase
      setup do
        # We want to keep tracking of import resource
        @import = Import.create!(nature: :panier_local_sales)

        I18n.locale = :fra
      end

      test 'import' do
        result = PanierLocal::IncomingPaymentsExchanger.build(fixture_files_path.join('imports', 'panier_local', 'panier_local_incoming_payments.csv'), options: { import_id: @import.id }).run
        assert result.success?, [result.message, result.exception]
        assert_equal 45, IncomingPayment.count
      end

      teardown do
        @import.destroy!
      end
    end
  end
end
