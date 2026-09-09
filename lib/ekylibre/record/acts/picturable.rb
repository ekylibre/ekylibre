# frozen_string_literal: true

module Ekylibre
  module Record
    module Acts
      ##
      # Gives a model a `picture` attachment with the three renditions the
      # application uses.
      #
      # Under Paperclip these were styles, generated at upload and stored on
      # disk. They are now Active Storage variants: computed on first request
      # and cached afterwards. The visible consequence is that the very first
      # display of a picture is slower; in exchange nothing redundant is stored,
      # and adding a rendition no longer means reprocessing everything.
      #
      # The transformations reproduce the Paperclip geometries exactly:
      #
      #   thumb    64x64>   fit inside the box, only shrinking
      #   identity 180x180^ fill the box then crop, centered
      #   contact  720x720^ same, larger
      #
      # `^` plus `extent` is what Paperclip's `#` geometry expanded to.
      module Picturable
        VARIANTS = {
          thumb: { resize: '64x64>', background: 'white', gravity: 'center', extent: '64x64' },
          identity: { resize: '180x180^', background: 'white', gravity: 'center', extent: '180x180' },
          contact: { resize: '720x720^', background: 'white', gravity: 'center', extent: '720x720' }
        }.freeze

        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          def has_picture(_options = {})
            include LegacyAttachmentColumns unless ancestors.include?(LegacyAttachmentColumns)

            has_one_attached :picture
            legacy_attachment_columns_for :picture

            # Remplace le validates_attachment_content_type de Paperclip, sans
            # équivalent en Active Storage sous Rails 5.2.
            validate do
              next unless picture.attached?

              errors.add(:picture, :invalid) unless picture.content_type.to_s.start_with?('image/')
            end

            # @return [Boolean]
            define_method(:has_picture?) { picture.attached? }

            # Rendition of the picture, or the picture itself for :original.
            #
            # @param style [Symbol] :original, :thumb, :identity or :contact
            # @return [ActiveStorage::Variant, ActiveStorage::Attached::One, nil]
            define_method(:picture_variant) do |style = :original|
              return nil unless picture.attached?
              return picture if style.to_sym == :original

              transformations = Picturable::VARIANTS.fetch(style.to_sym) do
                raise ArgumentError.new("Unknown picture style: #{style.inspect}")
              end
              picture.variant(transformations)
            end

            # Local filesystem path of a rendition, kept because several
            # controllers serialise it through `methods: [:picture_path]` and
            # the ODT printers need a real file.
            #
            # A variant only exists on disk once processed, hence the call.
            #
            # @param style [Symbol]
            # @return [String, nil] nil when nothing is attached, or when the
            #   storage service has no local path (object storage)
            define_method(:picture_path) do |style = :original|
              return nil unless picture.attached?

              service = ActiveStorage::Blob.service
              return nil unless service.respond_to?(:path_for)

              rendition = picture_variant(style)
              key = rendition.is_a?(ActiveStorage::Variant) ? rendition.processed.key : picture.key
              service.path_for(key)
            end

            # Yields that path to a block, mirroring with_<name>_path.
            define_method(:with_picture_path) do |&block|
              path = picture_path
              path.nil? ? nil : block.call(path)
            end
          end
        end
      end
    end
  end
end
