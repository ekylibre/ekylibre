# frozen_string_literal: true

require 'test_helper'

module Clients
  module Insee
    class FrenchVatTest < ActiveSupport::TestCase
      test 'derives the VAT number from a SIREN' do
        # key = (12 + 3 * (SIREN mod 97)) mod 97
        assert_equal 'FR12000000097', FrenchVat.from_siren('000000097') # 97 mod 97 = 0 → key 12
        assert_equal 'FR15000000001', FrenchVat.from_siren('000000001') # 1 → key 15
      end

      test 'ignores non-digits in the input' do
        assert_equal FrenchVat.from_siren('000000001'), FrenchVat.from_siren('000 000 001')
      end

      test 'returns nil when the SIREN is not 9 digits' do
        assert_nil FrenchVat.from_siren('123')
        assert_nil FrenchVat.from_siren(nil)
        assert_nil FrenchVat.from_siren('12345678901234')
      end
    end
  end
end
