# frozen_string_literal: true

module Printers
  # Base interface for Printers
  #
  # Each subclass should implement `key` and `generate`.
  class PrinterBase
    class << self
      def deprecated_filter(value, name)
        if value.nil? || value.is_a?(Array)
          value
        else
          ActiveSupport::Deprecation.warn "giving #{name} as a Hash from params is deprecated, you should pass an array containing only the active elements"

          value.select { |_k, v| v == '1' }.keys
        end
      end
    end

    attr_reader :template

    def initialize(template:)
      @template = template
    end

    # This method should use the provided `report` to generate the ODT file using the computed dataset
    #
    # @param [ODFReport::Report] report
    # @return [Array<byte>]
    def generate(report)
      raise NotImplementedError.new("`generate` should be implemented in subclasses")
    end

    # The key to identify documents belonging to the same record in database
    #
    # @return [String]
    def key
      raise NotImplementedError.new("`key` should be implemented in subclasses")
    end

    # Returns the document name. Used by DocumentArchiver to archive the Document in the Document Management System
    #
    # @return [String]
    def document_name
      "#{template.nature.human_name} - #{key}"
    end
  end
end
