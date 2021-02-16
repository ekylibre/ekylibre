module Telepac
  module V2015
    class CapStatementsExchanger < ActiveExchanger::Base
      include ExchangerMixin

      campaign 2015
      self.deprecated = true
    end
  end
end
