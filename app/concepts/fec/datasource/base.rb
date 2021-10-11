# frozen_string_literal: true

module FEC
  module Datasource
    class Base

      def initialize(financial_year, fiscal_position, started_on, stopped_on)
        @financial_year = financial_year
        @fiscal_position = fiscal_position
        @started_on = started_on
        @stopped_on = stopped_on
        # not closure or result journal in FEC Data
        @journals = Journal.where.not(nature: %w[closure result])
      end

      def perform
        raise NotImplementedError
      end
    end
  end
end
