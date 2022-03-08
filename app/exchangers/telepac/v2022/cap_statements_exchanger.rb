# frozen_string_literal: true

module Telepac
  module V2022
    class CapStatementsExchanger < ActiveExchanger::Base
      include ExchangerMixin

      campaign 2022
    end
  end
end
