# frozen_string_literal: true

module Attachments
  ##
  # Moves the files Paperclip wrote on disk into Active Storage.
  #
  # Paperclip derived its paths from the record, so nothing links a row to its
  # file any more once the declaration is gone: the paths are rebuilt here from
  # the interpolations that used to be in the models.
  #
  #   Document#file                       :tenant/documents/:id_partition/:style.:extension
  #   Guide#reference_source              :tenant/guides/:id/source.xml
  #   FinancialYearExchange#import_file   :tenant/financial_year_exchanges/:id/:style.:extension
  #   Import#archive                      :tenant/imports/:id/:style.:extension
  #   has_picture                         :tenant/:table/pictures/:id_partition/:style.:extension
  #
  # where `:tenant` is `<private directory>/attachments`.
  #
  # The extension is not recomputed: Paperclip sometimes wrote `original.` with
  # none at all. The original is located by globbing instead, and the name and
  # content type come from the legacy columns, which still hold what Paperclip
  # recorded.
  #
  # Idempotent: a record whose attachment is already present is skipped, so the
  # task can be replayed after an interruption.
  class PaperclipImporter
    # [model, attachment name, path builder]
    def self.specifications
      [
        [Document, :file, ->(record) { partitioned_directory(class_segment(record), record.id) }],
        [Guide, :reference_source, ->(record) { flat_directory(class_segment(record), record.id) }],
        [FinancialYearExchange, :import_file, ->(record) { flat_directory(class_segment(record), record.id) }],
        [Import, :archive, ->(record) { flat_directory(class_segment(record), record.id) }],
        *picture_specifications
      ]
    end

    def self.picture_specifications
      [Product, ProductNature, ProductNatureVariant, Issue, Entity].map do |model|
        [model, :picture, ->(record) { partitioned_directory("#{class_segment(record)}/pictures", record.id) }]
      end
    end

    # Paperclip's `:class` interpolation was the RECORD's class, not the table.
    # It matters for the STI hierarchies: a Product picture lives under
    # `equipments/` or `workers/`, never under `products/`. Confirmed against
    # the tenant archives in tmp/archives.
    #
    # @param record [ApplicationRecord]
    # @return [String]
    def self.class_segment(record)
      record.class.name.underscore.pluralize
    end

    def self.attachments_root
      Ekylibre::Tenant.private_directory.join('attachments')
    end

    # Paperclip's :id_partition — 9 digits split in groups of 3.
    def self.partitioned_directory(prefix, id)
      attachments_root.join(prefix, *format('%09d', id).scan(/\d{3}/))
    end

    def self.flat_directory(prefix, id)
      attachments_root.join(prefix, id.to_s)
    end

    # @param dry_run [Boolean] inventory only, write nothing
    # @param logger [#call] receives one line per message
    def initialize(dry_run: false, logger: ->(line) { Rails.logger.info(line) })
      @dry_run = dry_run
      @logger = logger
      @counters = Hash.new(0)
    end

    # @return [Hash{Symbol=>Integer}] :migrated, :missing, :skipped
    def run
      self.class.specifications.each { |model, name, directory_for| import(model, name, directory_for) }
      @counters
    end

    private

      attr_reader :dry_run, :logger

      def import(model, name, directory_for)
        # Une fois DropPaperclipColumns passée, plus rien n'est à reprendre et
        # la colonne n'existe plus : filtrer dessus lèverait PG::UndefinedColumn.
        return unless model.column_names.include?("#{name}_file_name")

        scope = model.where.not("#{name}_file_name" => nil)
        return if scope.none?

        scope.find_each do |record|
          if record.public_send(name).attached?
            @counters[:skipped] += 1
            next
          end

          source = original_file_in(directory_for.call(record))
          if source.nil?
            @counters[:missing] += 1
            logger.call("  MANQUANT  #{model.name}##{record.id} #{record.public_send(:"#{name}_file_name")}")
            next
          end

          @counters[:migrated] += 1
          logger.call("  repris    #{model.name}##{record.id} #{File.basename(source)}")
          next if dry_run

          attach(record, name, source)
        end
      end

      # Paperclip did not always write an extension, hence the glob.
      #
      # @return [String, nil]
      def original_file_in(directory)
        Dir[File.join(directory.to_s, 'original*'), File.join(directory.to_s, 'source.xml')].find { |path| File.file?(path) }
      end

      def attach(record, name, source)
        # Skip the derivative rebuild: for a Document the PDF and thumbnail
        # Paperclip already produced are imported below, which spares a
        # LibreOffice run per document.
        record.skip_derivatives = true if record.respond_to?(:skip_derivatives=)

        record.public_send(name).attach(
          io: File.open(source),
          filename: record.public_send(:"#{name}_file_name").presence || File.basename(source),
          content_type: record.public_send(:"#{name}_content_type").presence
        )

        import_document_derivatives(record, File.dirname(source)) if record.is_a?(Document)
      end

      # The :default and :thumbnail styles are now the pdf_rendition and
      # thumbnail attachments.
      def import_document_derivatives(document, directory)
        { pdf_rendition: ['default.pdf', 'application/pdf'],
          thumbnail: ['thumbnail.jpg', 'image/jpeg'] }.each do |attachment, (basename, content_type)|
          path = File.join(directory, basename)
          next unless File.file?(path)
          next if document.public_send(attachment).attached?

          document.public_send(attachment).attach(io: File.open(path), filename: basename, content_type: content_type)
        end
      end
  end
end
