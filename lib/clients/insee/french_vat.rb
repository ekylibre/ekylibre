# frozen_string_literal: true

module Clients
  module Insee
    # Derives the French intra-community VAT number from a SIREN.
    # FR + 2-digit key + SIREN, key = (12 + 3 * (SIREN mod 97)) mod 97.
    module FrenchVat
      module_function

      def from_siren(siren)
        digits = siren.to_s.gsub(/[^0-9]/, '')
        return nil unless digits.length == 9

        key = (12 + 3 * (digits.to_i % 97)) % 97
        format('FR%02d%s', key, digits)
      end
    end
  end
end
