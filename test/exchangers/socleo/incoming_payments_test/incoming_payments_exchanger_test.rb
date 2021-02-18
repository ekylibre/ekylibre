require 'test_helper'

module Socleo
  module IncomingPaymentsTest
    class IncomingPaymentsExchangerTest < ActiveExchanger::TestCase
      setup do
        # We want to keep tracking of import resource
        @import = Import.create!(nature: :socleo_sales)

        I18n.locale = :fra
      end

      test 'import' do
        result = Socleo::IncomingPaymentsExchanger.build(fixture_files_path.join('imports', 'socleo', 'socleo_incoming_payments.csv'), options: { import_id: @import.id }).run
        assert result.success?, [result.message, result.exception]
        assert_equal 45, IncomingPayment.count
      end

      teardown do
        @import.destroy!
      end
    end
  end
end
