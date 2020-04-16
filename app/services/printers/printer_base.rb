module Printers
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

    include Concerns::PdfPrinter

    attr_reader :template, :template_path

    def initialize(template:)
      @template = template
      @template_path = find_template(template)
    end

    def key
      raise NotImplementedError, "`key` should be implemented in subclasses"
    end

    def document_name
      "#{template.nature.human_name} - #{key}"
    end
  end
end
