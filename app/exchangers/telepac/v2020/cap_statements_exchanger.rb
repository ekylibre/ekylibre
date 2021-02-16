module Telepac
  module V2020
    class CapStatementsExchanger < ActiveExchanger::Base
      include ExchangerMixin

      campaign 2020
    end
  end
end
