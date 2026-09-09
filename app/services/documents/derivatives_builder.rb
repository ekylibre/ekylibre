# frozen_string_literal: true

require 'open3'

module Documents
  ##
  # Rebuilds everything Paperclip used to derive from an uploaded document.
  #
  # The `:default` and `:thumbnail` styles ran four processors from the
  # paperclip-document gem, all backed by Docsplit:
  #
  #   reader   -> OCR text        -> file_content_text
  #   counter  -> number of pages -> file_pages_count
  #   freezer  -> PDF rendition   -> now the `pdf_rendition` attachment
  #   sketcher -> first page      -> now the `thumbnail` attachment
  #
  # Active Storage variants only cover images, so these are plain attachments
  # built here instead. The work stays synchronous, as it was under Paperclip:
  # the show page links to the thumbnail right after upload.
  class DerivativesBuilder
    THUMBNAIL_GEOMETRY = '320x320>'
    THUMBNAIL_DENSITY = 150

    # @param document [Document]
    def initialize(document)
      @document = document
    end

    # @return [Boolean] false when there is nothing to derive
    def build
      return false unless document.file.attached?

      document.with_file_path do |path|
        Dir.mktmpdir('document-derivatives') do |workdir|
          extract_text(path, workdir)
          extract_pages_count(path)
          attach_pdf_rendition(path, workdir)
          attach_thumbnail(path, workdir)
        end
      end

      document.save!(validate: false)
      true
    end

    private

      attr_reader :document

      def basename_of(path)
        File.basename(path, File.extname(path))
      end

      def pdf?(path)
        File.open(path, 'rb', &:readline).to_s.match?(/\A%PDF-\d+(\.\d+)?/)
      rescue EOFError, ArgumentError
        false
      end

      def extract_text(path, workdir)
        Docsplit.extract_text(path, output: workdir, clean: false)
        text_file = File.join(workdir, "#{basename_of(path)}.txt")
        return unless File.exist?(text_file)

        document.file_content_text = File.read(text_file).truncate(500_000)
      rescue StandardError => e
        # Paperclip ran with `whiny = false`: a document that resists text
        # extraction was stored anyway. Keep that, but say so in the log.
        Rails.logger.warn("[Document ##{document.id}] text extraction failed: #{e.message}")
      end

      def extract_pages_count(path)
        document.file_pages_count = Docsplit.extract_length(path)
      rescue StandardError => e
        Rails.logger.warn("[Document ##{document.id}] page count failed: #{e.message}")
      end

      def attach_pdf_rendition(path, workdir)
        source = if pdf?(path)
                   path
                 else
                   Docsplit.extract_pdf(path, output: workdir)
                   File.join(workdir, "#{basename_of(path)}.pdf")
                 end
        return unless File.exist?(source)

        document.pdf_rendition.attach(
          io: File.open(source),
          filename: "#{basename_of(document.file.filename.to_s)}.pdf",
          content_type: 'application/pdf'
        )
      rescue StandardError => e
        Rails.logger.warn("[Document ##{document.id}] PDF rendition failed: #{e.message}")
      end

      # The sketcher processor went through Docsplit, whose wrapper fails here
      # with an empty message even though `gm` and Ghostscript are both present
      # and work when called directly. GraphicsMagick is invoked straight
      # instead: fewer moving parts, and errors that can actually be read.
      #
      # The source is the PDF rendition when there is one — a page of a document
      # only becomes an image once it is a PDF — and the original otherwise,
      # which covers documents that are already images.
      def attach_thumbnail(path, workdir)
        source = thumbnail_source(path, workdir)
        return if source.nil?

        image = File.join(workdir, 'thumbnail.jpg')
        _out, error, status = Open3.capture3(
          'gm', 'convert', '-density', THUMBNAIL_DENSITY.to_s,
          "#{source}[0]", '-resize', THUMBNAIL_GEOMETRY, image
        )
        unless status.success? && File.exist?(image)
          Rails.logger.warn("[Document ##{document.id}] thumbnail failed: #{error.strip}")
          return
        end

        document.thumbnail.attach(io: File.open(image), filename: 'thumbnail.jpg', content_type: 'image/jpeg')
      rescue StandardError => e
        Rails.logger.warn("[Document ##{document.id}] thumbnail failed: #{e.message}")
      end

      # @return [String, nil]
      def thumbnail_source(path, workdir)
        return path if pdf?(path) || document.file.content_type.to_s.start_with?('image/')

        converted = File.join(workdir, "#{basename_of(path)}.pdf")
        File.exist?(converted) ? converted : nil
      end
  end
end
