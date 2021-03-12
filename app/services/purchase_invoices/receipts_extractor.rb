# frozen_string_literal: true

module PurchaseInvoices
  class ReceiptsExtractor

    class << self
      def build
        new
      end
    end

    # @param [Array<FinancialYear>] financial_years
    # @return [Document]
    def create_zip(*financial_years)
      Dir.mktmpdir do |tmpdir|
        root = Pathname.new(tmpdir)

        financial_years.each do |fy|
          fy_path = root.join(fy.name)
          fy_path.mkdir
          purchase_invoices = PurchaseInvoice.invoiced_between(fy.started_on, fy.stopped_on)
          pis_by_month = purchase_invoices.group_by { |pi| [pi.invoiced_at.strftime('%m'), pi.invoiced_at.strftime('%Y')] }

          pis_by_month.each do |date, pis|
            bundle_pdf(pis, destination: fy_path.join(:pdf_purchase_receipt_file_name.tl(month: date.first, year: date.last)))
          end
        end

        generator = ExportTools::ZipFileGenerator.new
        generator.compress_folder(root) do |zip_file_path|
          name = :purchase_receipts_file_name.tl
          Document.create!(name: name, processable_attachment: false, file: File.open(zip_file_path), file_file_name: "#{name.parameterize}.zip")
        end
      end
    end

    # @param [Array<PurchaseInvoice>]
    # @param [Pathname] destination
    def bundle_pdf(purchase_invoices, destination:)
      Dir.mktmpdir do |tmpdir|
        tmp_path = Pathname.new(tmpdir)
        pdf = CombinePDF.new

        purchase_invoices.each do |invoice|
          next if invoice.attachments.empty?

          document = make_separator(invoice.number, tmp_path)
          pdf << CombinePDF.load(document)

          invoice.attachments.each do |attachment|
            pdf << CombinePDF.load(attachment.document.file.path)
          end
        end

        pdf.save(destination)
      end
    end

    def make_separator(number, dir)
      path = dir.join("#{number}.pdf")

      pdf = Prawn::Document.generate(path, page_size: 'A4', page_layout: :portrait) do
        text number, align: :center, size: 21
      end

      path
    end
  end
end
