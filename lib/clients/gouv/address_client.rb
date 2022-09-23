module Clients
  module Gouv
    class AddressClient
      BASE_URL = 'https://api-adresse.data.gouv.fr/search/'.freeze

      def get_address(address)
        call = RestClient.get(address_url(address))
        JSON.parse(call.body).deep_symbolize_keys
      end

      private

        def address_url(address)
          encoded_address = URI.encode(address)
          BASE_URL + "?q=#{encoded_address}&type=housenumber&autocomplete=0"
        end
    end
  end
end
