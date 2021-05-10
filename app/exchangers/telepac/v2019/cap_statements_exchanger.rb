# frozen_string_literal: true

module Telepac
  module V2019
    class CapStatementsExchanger < ActiveExchanger::Base
      include ExchangerMixin

      campaign 2019
    end
  end
end
