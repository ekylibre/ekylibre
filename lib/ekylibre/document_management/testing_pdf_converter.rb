# frozen_string_literal: true

module Ekylibre
  module DocumentManagement
    class TestingPdfConverter
      class << self
        def build
          new(file: Rails.root.join('test', 'fixture-files', 'document_management', 'dummy_pdf.pdf'))
        end
      end

      # @param [Pathname] file
      def initialize(file:)
        @file = file
      end

      # @param [Array<byte>] _odt_data
      def convert_data(_odt_data)
        file.binread
      end

      private

        # @return [Pathname]
        attr_reader :file

    end
  end
end
