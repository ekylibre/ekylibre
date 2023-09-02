# frozen_string_literal: true

module Telepac
  module V2023
    class CapStatementsExchanger < ActiveExchanger::Base
      include ExchangerMixin

      campaign 2023
    end
  end
end
