# frozen_string_literal: true

module Ekylibre
  module DocumentManagement
    class SignatureManager
      class << self
        def build
          new
        end
      end

      # @param [Document] document
      # @param [User] user
      def sign(document:, user:)
        sha256 = Digest::SHA256.file(document.file.path)
        crypto = GPGME::Crypto.new
        signature = crypto.clearsign(sha256.to_s, signer: ENV['GPG_EMAIL'])
        signature_path = document.file.path.gsub(document_extension(document), '.asc')
        File.write(signature_path, signature)
        document.update!(sha256_fingerprint: sha256.to_s, signature: signature.to_s, mandatory: true, creator: user, updater: user)
      end

      private

        def document_extension(document)
          File.extname(document.file.path)
        end
    end
  end
end
