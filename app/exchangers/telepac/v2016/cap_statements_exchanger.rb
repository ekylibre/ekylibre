# frozen_string_literal: true

module Telepac
  module V2016
    class CapStatementsExchanger < ActiveExchanger::Base
      include ExchangerMixin

      campaign 2016
      self.deprecated = true
    end
  end
end
