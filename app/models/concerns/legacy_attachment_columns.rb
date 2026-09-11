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

  # Paperclip acceptait `attachment = File.open(path)` ; Active Storage exige
  # un attachable qu'il sache reconnaître, et Rails 6 lève une `ArgumentError`
  # sur le reste — Rails 5.2 se contentait de ne rien attacher, en silence.
  #
  # Un io sans chemin (StringIO) reste refusé : son nom ne peut pas être
  # deviné, et l'inventer produirait des pièces jointes intitulées « blob ».
  # Ces appels-là doivent passer par une méthode qui reçoit le nom, comme
  # `Document#attach_file` ou `Import#attach_archive`.
  #
  # @param attachable [File, Pathname, ActiveStorage::Blob, Hash, String, nil]
  # @param origin [String] nom de l'écrivain, pour le message d'erreur
  # @return [Object] un attachable qu'Active Storage sait reconnaître
  # @raise [ArgumentError] si le nom de fichier ne peut pas être déduit
  def self.normalize_attachable(attachable, origin: 'attachment')
    case attachable
    when ::Pathname
      { io: File.open(attachable), filename: attachable.basename.to_s }
    when ::File
      { io: attachable, filename: File.basename(attachable.path) }
    when ::IO, ::StringIO
      raise ArgumentError.new("#{origin} : un io sans chemin n'a pas de nom de fichier")
    else
      attachable
    end
  end

  # Construit un blob dont le fichier est **déjà** écrit sur le service.
  #
  # Depuis Rails 6, `attach` ne téléverse plus pendant la sauvegarde mais dans
  # un `after_commit` : à l'intérieur d'une transaction — tout `first_run`, tout
  # import — `attached?` répond oui alors qu'aucun fichier n'existe encore, et
  # la lecture du chemin échoue en `Errno::ENOENT`. Rails 5.2 téléversait au
  # moment de la création du blob.
  #
  # `create_and_upload!` est le nom depuis Rails 6 ; `create_after_upload!`
  # celui de 5.2, qui n'en est plus qu'un alias.
  #
  # @return [ActiveStorage::Blob]
  def self.upload_blob(io:, filename:, content_type: nil)
    attributes = { io: io, filename: filename, content_type: content_type }.compact
    if ::ActiveStorage::Blob.respond_to?(:create_and_upload!)
      ::ActiveStorage::Blob.create_and_upload!(**attributes)
    else
      ::ActiveStorage::Blob.create_after_upload!(**attributes)
    end
  end

  module ClassMethods
    # @param name [Symbol] name of the Active Storage attachment
    def legacy_attachment_columns_for(name)
      # `has_one_attached` définit l'écrivain **directement sur la classe** en
      # Rails 5.2 — ce n'est qu'en Rails 6 qu'il passe par un module inclus.
      # Une redéfinition avec `super` n'aurait donc aucune cible : d'où le
      # module anonyme préposé.
      origin = "#{self.name}##{name}="
      prepend(Module.new do
        define_method("#{name}=") do |attachable|
          super(LegacyAttachmentColumns.normalize_attachable(attachable, origin: origin))
        end
      end)

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
