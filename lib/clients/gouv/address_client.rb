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
          # `URI.encode` a disparu avec Ruby 3.0. `url_encode` échappe tout ce
          # qui n'est pas littéral dans une valeur de paramètre, l'espace inclus.
          BASE_URL + "?q=#{ERB::Util.url_encode(address.to_s)}&type=housenumber&autocomplete=0"
        end
    end
  end
end
