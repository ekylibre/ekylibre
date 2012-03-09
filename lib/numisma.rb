# This module aimed to structure and controls currencies through the application
# It represents the international monetary system with all its currencies like specified in ISO 4217
# Numisma comes from latin: It designs here the "science of money"
require 'numisma/currency'
# require 'numisma/money'
module Numisma
  mattr_reader :currencies

  class << self

    # Returns the path to currencies file
    def currencies_file
      Rails.root.join("config", "currencies.yml")
    end
    
    # Returns a hash with active currencies only
    def active_currencies
      x = {}
      for code, currency in @@currencies
        x[code] = currency if currency.active
      end
      return x
    end
    
    # Shorcut to get currency
    def [](currency_code)
      @@currencies[currency_code]
    end
    
    
    # Load currencies
    def load_currencies
      @@currencies = {}
      for code, details in YAML.load_file(self.currencies_file)
        currency = Currency.new(code, details.symbolize_keys)
        @@currencies[currency.code] = currency
      end
    end
  end

  # Finally load all currencies
  load_currencies
end
