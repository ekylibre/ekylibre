require 'test_helper'

module PanierLocal
  module IncomingPaymentsTest
    class IncomingPaymentsExchangerUnitTest < Ekylibre::Testing::ApplicationTestCase
      setup do
        # We wan't to keep tracking of import resource
        @import = Import.create!(nature: :panier_local_incoming_payments)
        @e = PanierLocal::IncomingPaymentsExchanger.new('', '', import_id: @import.id)
      end

      test 'payment_mode provider find' do
        assert_nil @e.find_payment_mode_by_provider
        ipm = create :incoming_payment_mode, provider: { vendor: :panier_local, name: :incoming_payments, id: 42 }
        assert_equal ipm, @e.find_payment_mode_by_provider
      end

      test 'payment_mode is created if not found by provider' do
        cash = create :cash

        stub_many @e, find_payment_mode_by_provider: nil, default_cash: cash do
          ipm = @e.find_or_create_payment_mode

          assert ipm
          assert ipm.is_provided_by?(vendor: 'panier_local', name: 'incoming_payments')
          assert_equal cash, ipm.cash
        end
      end

      test 'incoming_payment provider find' do
        create :financial_year, year: 2020

        assert_nil @e.find_incoming_payment_by_provider("42")
        ip = create :incoming_payment, at: Date.new(2020, 1, 2), provider: { vendor: :panier_local, name: :incoming_payments, id: 42, data: { sale_reference_number: "42" } }
        assert_equal ip, @e.find_incoming_payment_by_provider("42")
      end

      test 'incoming_payment is created if not found by provider' do
        payment_info = [
          { account_number: '4111', entity_name: '', entity_code: '', sale_reference_number: "refnum" }.to_struct,
          { account_number: '512', invoiced_at: '2020-01-02T10:00:00Z', sale_reference_number: "refnum" }.to_struct
        ]

        create :financial_year, year: 2020
        entity = create :entity, :client
        payment_mode = create :incoming_payment_mode
        ip = nil

        stub_many @e, find_incoming_payment_by_provider: nil, find_or_create_entity: entity, get_incoming_payment_amount: 456.0, client_account_radix: '4111' do
          ip = @e.find_or_create_incoming_payment(payment_info, payment_mode)

          assert ip
          assert ip.is_provided_by?(vendor: 'panier_local', name: 'incoming_payments')
          assert_equal "refnum", ip.provider_data.fetch(:sale_reference_number)
          assert_equal 456.0, ip.amount
        end

        assert_equal ip, @e.find_incoming_payment_by_provider("refnum")
      end

      teardown do
        @import.destroy!
      end
    end
  end
end
