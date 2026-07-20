# frozen_string_literal: true

module Ekylibre
  module DocumentManagement
    class SignatureManager
      class SignatureError < StandardError; end

      class << self
        def build
          new
        end
      end

      # @param [Document] document
      # @param [User] user
      def sign(document:, user:)
        sha256 = Digest::SHA256.file(document.file.path)
        ensure_gpg_key_usable!
        crypto = GPGME::Crypto.new
        signature = crypto.clearsign(sha256.to_s, signer: ENV['GPG_EMAIL'])
        signature_path = document.file.path.gsub(document_extension(document), '.asc')
        File.write(signature_path, signature)
        document.update!(sha256_fingerprint: sha256.to_s, signature: signature.to_s, mandatory: true, creator: user, updater: user)
      rescue ArgumentError => e
        # gpgme-2.0.x bug: quand ctx.sign leve UnusableSecretKey/BadPassphrase,
        # le rescue de crypto.rb:251 appelle ctx.sign_result qui renvoie NULL,
        # ce qui fait remonter un "NULL pointer given" opaque a la place de
        # l'erreur reelle. Voir docker/prod/GPG.md §10.
        raise unless e.message.include?('NULL pointer')
        raise SignatureError, "GPG signature failed for '#{ENV['GPG_EMAIL']}' (masked by gpgme rescue bug). Common causes: keyring mounted read-only (gpg-agent cannot start), key not trusted ultimate, missing keygrip in private-keys-v1.d/, or key has a passphrase. See docker/prod/GPG.md §10."
      end

      private

        def document_extension(document)
          File.extname(document.file.path)
        end

        def ensure_gpg_key_usable!
          email = ENV['GPG_EMAIL']
          raise SignatureError, 'GPG_EMAIL is blank — cannot sign document.' if email.blank?
          return if GPGME::Key.find(:secret, email, :sign).any?

          raise SignatureError, "No usable secret GPG key found for '#{email}'. Check `gpg --list-secret-keys` inside the container and docker/prod/GPG.md §10."
        end
    end
  end
end
