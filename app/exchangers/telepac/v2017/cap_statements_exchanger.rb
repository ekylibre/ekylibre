# frozen_string_literal: true

module Telepac
  module V2017
    class CapStatementsExchanger < ActiveExchanger::Base
      include ExchangerMixin

      campaign 2017
    end
  end
end
