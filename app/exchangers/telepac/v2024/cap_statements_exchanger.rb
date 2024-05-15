# frozen_string_literal: true

module Telepac
  module V2024
    class CapStatementsExchanger < ActiveExchanger::Base
      include ExchangerMixin

      campaign 2024
    end
  end
end
