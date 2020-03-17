module Printers
  class PrinterBase
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
