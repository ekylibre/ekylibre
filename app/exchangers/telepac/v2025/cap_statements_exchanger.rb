# frozen_string_literal: true

module Telepac
  module V2025
    class CapStatementsExchanger < ActiveExchanger::Base
      include ExchangerMixin

      campaign 2025
    end
  end
end
