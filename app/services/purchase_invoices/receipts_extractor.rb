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
          # replace / by - because path/folder don't like ∕ in name
          fy_path = root.join(fy.name.gsub("/", "-"))
          fy_path.mkdir
          purchase_invoices = PurchaseInvoice.invoiced_between(fy.started_on, fy.stopped_on).reorder(:invoiced_at)
          pis_by_month = purchase_invoices.group_by { |pi| [pi.invoiced_at.strftime('%m'), pi.invoiced_at.strftime('%Y')] }

          pis_by_month.each do |date, pis|
            bundle_pdf(pis, destination: fy_path.join(:pdf_purchase_receipt_file_name.tl(month: date.first, year: date.last)))
          end
        end

        generator = ExportTools::ZipFileGenerator.new
        generator.compress_folder(root) do |zip_file_path|
          name = :purchase_receipts_file_name.tl
          Document.create!(name: "#{name}.zip", processable_attachment: false, file: File.open(zip_file_path), file_file_name: "#{name.parameterize}.zip")
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

          if invoice.attachments.empty?
            document = make_separator(invoice, tmp_path, false)
            pdf << CombinePDF.load(document)
            next
          else
            document = make_separator(invoice, tmp_path, true)
            pdf << CombinePDF.load(document)
            invoice.attachments.each do |attachment|
              # get default path (pdf) evenif doc is image or text
              pdf_attachment_path = attachment.document&.file&.path(:default)
              if pdf_attachment_path
                begin
                  attach_pdf = CombinePDF.load(pdf_attachment_path, allow_optional_content: true)
                rescue
                  puts "Error on merging PDF".inspect.yellow
                end
                pdf << attach_pdf
              end
            end
          end
        end
        pdf.save(destination)
      end
    end

    def make_separator(invoice, dir, attachments)
      path = dir.join("#{invoice.number}.pdf")

      pdf = Prawn::Document.generate(path, page_size: 'A4', page_layout: :portrait) do
        move_down 300
        text "#{:purchase_receipts_export_file.tl} | #{invoice.invoiced_at.strftime('%m/%Y')}", align: :center, size: 26
        move_down 30
        text "#{:purchase_invoice_number.tl} : #{invoice.number}", align: :center, size: 21
        move_down 30
        text "#{:invoice_date_export_file.tl} : #{invoice.invoiced_at.strftime('%d/%m/%Y')}", align: :center, size: 21
        move_down 30
        text :reference_supplier.tl(reference_number: invoice.reference_number), align: :center, size: 16, inline_format: true
        move_down 30
        text :created_at_by.th(at: invoice.created_at.l, author: (invoice.creator&.name || :unknown_user.tl)), align: :center, size: 16, inline_format: true
        if attachments == false
          move_down 100
          text :no_invoice_receipts_for_purchase_invoice.tl, align: :center, size: 20, color: 'ff0000'
        end
      end

      path
    end
  end
end
