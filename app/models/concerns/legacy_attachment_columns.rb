# frozen_string_literal: true

##
# = Legacy attachment columns
#
# Paperclip stored four columns per attachment — `<name>_file_name`,
# `<name>_content_type`, `<name>_file_size` and `<name>_updated_at` — and the
# application reads them in about a hundred places (list columns, mailers,
# exchangers, views).
#
# Active Storage keeps the same information on the blob instead. This concern
# redirects the historical readers to the attachment so those call sites keep
# working, which is what makes the migration model-by-model rather than
# big-bang.
#
# The columns are gone since DropPaperclipColumns, but the fallback on
# `self[...]` stays: `read_attribute` returns nil for an unknown attribute
# rather than raising, and the fallback is what ImportPaperclipAttachments reads
# to recover a file's original name and type — at that point in the migration
# series the columns are still there.
module LegacyAttachmentColumns
  extend ActiveSupport::Concern

  module ClassMethods
    # @param name [Symbol] name of the Active Storage attachment
    def legacy_attachment_columns_for(name)
      define_method("#{name}_file_name") do
        attachment = public_send(name)
        attachment.attached? ? attachment.filename.to_s : self[:"#{name}_file_name"]
      end

      define_method("#{name}_content_type") do
        attachment = public_send(name)
        attachment.attached? ? attachment.content_type : self[:"#{name}_content_type"]
      end

      define_method("#{name}_file_size") do
        attachment = public_send(name)
        attachment.attached? ? attachment.byte_size : self[:"#{name}_file_size"]
      end

      define_method("#{name}_updated_at") do
        attachment = public_send(name)
        attachment.attached? ? attachment.blob.created_at : self[:"#{name}_updated_at"]
      end

      # Materialises the attachment as a local file for the duration of the
      # block. Active Storage exposes no local path of its own, and Rails 5.2
      # has no `Blob#open` yet — only `download`.
      #
      # On the Disk service the file is already on disk, so its real path is
      # handed over directly. Any other service falls back to a tempfile, which
      # keeps this valid if storage ever moves to object storage.
      #
      # @yieldparam [String] path of a readable local file
      # @return [Object, nil] the block's value, or nil when nothing is attached
      define_method("with_#{name}_path") do |&block|
        attachment = public_send(name)
        return nil unless attachment.attached?

        service = ActiveStorage::Blob.service
        if service.respond_to?(:path_for)
          block.call(service.path_for(attachment.key))
        else
          extension = File.extname(attachment.filename.to_s)
          Tempfile.create([File.basename(attachment.filename.to_s, extension), extension]) do |tempfile|
            tempfile.binmode
            attachment.blob.download { |chunk| tempfile.write(chunk) }
            tempfile.flush
            block.call(tempfile.path)
          end
        end
      end
    end
  end
end
