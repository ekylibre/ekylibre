# frozen_string_literal: true

module Telepac
  module V2021
    class CapStatementsExchanger < ActiveExchanger::Base
      include ExchangerMixin

      campaign 2021
    end
  end
end
