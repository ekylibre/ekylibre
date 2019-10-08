module PdfPrinter
  extend ActiveSupport::Concern

  included do
    include Printers::Concerns::PdfPrinter

    ActiveSupport::Deprecation.warn "The use of the constant PdfPrinter is deprectaed, use Printers::PdfPrinter instead. I'll do it for you this time."
  end
end
