module Attachable
  extend ActiveSupport::Concern

  included do
    has_many :attachments, as: :resource

    def attachments=(documents)
      if documents
        documents[:files].each do |file|
          key= "#{Time.now.to_i.to_s}-#{file.original_filename}"
          self.attachments.create!(document_attributes:{file: file, name: file.original_filename, key: key, uploaded: true})
        end
      end
    end

  end
end
