# frozen_string_literal: true

module Lexicon
  module Package
    class SourceFileSet
      attr_reader :id, :name, :structure_path, :data_path, :tables

      # @param [String] id
      # @param [String] name
      # @param [String] structure
      # @param [String] data
      # @param [Array<String>] tables
      def initialize(id:, name:, structure:, data:, tables:)
        @id = id
        @name = name
        @structure_path = structure
        @data_path = data
        @tables = tables
      end
    end
  end
end
