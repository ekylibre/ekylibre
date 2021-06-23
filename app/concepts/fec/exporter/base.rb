# frozen_string_literal: true

module FEC
  module Exporter
    class Base
      attr_reader :financial_year, :fiscal_position

      def initialize(financial_year, fiscal_position = nil, started_on, stopped_on)
        @datasource = FEC::Datasource::Exporter.new(financial_year, fiscal_position, started_on, stopped_on).perform
        @fiscal_position = fiscal_position
      end

      def write(path)
        File.write(path, generate)
      end

      def generate
        build(@datasource)
      end

      private

        def build(_journals)
          raise NotImplementedError
        end

    end
  end
end
