# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2023 Ekylibre SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: documents
#
#  created_at             :datetime         not null
#  creator_id             :integer(4)
#  custom_fields          :jsonb
#  file_content_text      :text
#  file_pages_count       :integer(4)
#  id                     :integer(4)       not null, primary key
#  key                    :string           not null
#  metadata               :jsonb            default("{}")
#  lock_version           :integer(4)       default(0), not null
#  mandatory              :boolean          default(FALSE)
#  name                   :string           not null
#  nature                 :string
#  number                 :string           not null
#  processable_attachment :boolean          default(TRUE), not null
#  sha256_fingerprint     :string
#  signature              :text
#  template_id            :integer(4)
#  updated_at             :datetime         not null
#  updater_id             :integer(4)
#  uploaded               :boolean          default(FALSE), not null
#

class Document < ApplicationRecord
  include Customizable
  include LegacyAttachmentColumns
  belongs_to :template, class_name: 'DocumentTemplate'
  has_many :attachments, dependent: :destroy, inverse_of: :document
  has_one_attached :file
  legacy_attachment_columns_for :file

  # Ce que Paperclip produisait sous les styles :default et :thumbnail. Les
  # variantes Active Storage ne couvrant que les images, ce sont des pièces
  # jointes à part entière, construites par Documents::DerivativesBuilder.
  has_one_attached :pdf_rendition
  has_one_attached :thumbnail
  refers_to :nature, class_name: 'DocumentNature'
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :file_content_text, :signature, length: { maximum: 500_000 }, allow_blank: true
  validates :sha256_fingerprint, length: { maximum: 500 }, allow_blank: true
  validates :key, :name, :number, presence: true, length: { maximum: 500 }
  validates :mandatory, inclusion: { in: [true, false] }, allow_blank: true
  validates :processable_attachment, :uploaded, inclusion: { in: [true, false] }
  # ]VALIDATORS]
  validates :number, length: { allow_nil: true, maximum: 60 }
  validates :nature, length: { allow_nil: true, maximum: 120 }
  # validates_inclusion_of :nature, in: nature.values
  # validates_attachment_presence :file
  # Paperclip fournissait validates_attachment_content_type ; Active Storage
  # n'a pas d'équivalent en Rails 5.2.
  validate do
    next unless file.attached?

    errors.add(:file, :invalid) unless file.content_type.to_s.match?(%r{\A(application|image|text)/})
  end

  delegate :name, to: :template, prefix: true
  acts_as_numbered

  protect(on: :destroy) do
    mandatory || under_legal_retention?
  end

  def under_legal_retention?
    legal_retention_until.present? && legal_retention_until >= Date.current
  end

  # Returns the matching unique document for the given nature and key
  def self.of(nature, key)
    where(nature: nature.to_s, key: key.to_s)
  end

  # Attache un contenu dont le nom ne se déduit pas de lui-même.
  #
  # @param content [IO, String, Pathname, File] contenu ou chemin
  # @param filename [String]
  # @param content_type [String, nil] laissé à la détection si absent
  # @return [self]
  def attach_file(content, filename:, content_type: nil)
    io = case content
         when ::String then StringIO.new(content)
         when ::Pathname then File.open(content)
         else content
         end
    file.attach(LegacyAttachmentColumns.upload_blob(io: io, filename: filename, content_type: content_type))
    self
  end

  before_validation do
    # `file.filename` n'est disponible qu'une fois la pièce jointe assignée ;
    # Paperclip exposait original_filename dès l'affectation.
    if file.attached?
      self.name ||= file.filename.to_s
      self.key ||= "#{Time.now.to_i}-#{file.filename}"
    end
    # DB limitation
    self.file_content_text = file_content_text.truncate(500_000) if file_content_text
  end

  # Les dérivés (texte, nombre de pages, PDF, vignette) étaient produits par les
  # processeurs Paperclip au moment du post-traitement. Ils le sont désormais
  # après commit, une fois la pièce jointe réellement enregistrée — et toujours
  # de façon synchrone, la page de consultation liant la vignette dès l'envoi.
  # Permet à la reprise de données (rake attachments:migrate_to_active_storage)
  # de rattacher les rendus déjà produits par Paperclip au lieu de relancer
  # LibreOffice sur chaque document.
  attr_accessor :skip_derivatives

  # La garde de réentrance est indispensable : le builder attache le PDF et la
  # vignette, et chaque `attach` sauvegarde l'enregistrement, ce qui rappelle ce
  # même callback. Sans elle, la construction boucle jusqu'au SystemStackError.
  after_commit on: %i[create update] do
    unless skip_derivatives || @building_derivatives || !processable_attachment? || !file.attached? ||
           (pdf_rendition.attached? && thumbnail.attached?)
      @building_derivatives = true
      begin
        Documents::DerivativesBuilder.new(self).build
      ensure
        @building_derivatives = false
      end
    end
  end

  def attachement_presence
    if self.attachments
      true
    else
      false
    end
  end

  def ocr_presence
    self.metadata.present?
  end

  # known if a document has already a purchase link to him
  # return nil or Purchase
  def attach_to_resource(nature = "Purchase")
    attach = self.attachments.where(resource_type: nature)
    if attach.any?
      attach.first.resource_id
    else
      nil
    end
  end

  # Caution: if you set processable_attachment to false when creating a zip document put it before the file
  # like this => Document.create!(name: file_name, processable_attachment: false, file: File.open(file_path))
  # not like this => Document.create!(name: file_name, file: File.open(file_path), processable_attachment: false)
  def processable_attachment?
    processable_attachment
  end

  def file_size
    size_ko = 1000.to_f
    size_mo = (size_ko * size_ko).to_f
    size_go = (size_mo * size_ko).to_f
    size_terra = (size_go * size_ko).to_f

    if !self.file_file_size.nil? && self.file_file_size.to_d > 0
      if self.file_file_size < size_mo
        "#{(self.file_file_size/size_ko).round(2)} Ko"
      elsif self.file_file_size < size_go
        "#{(self.file_file_size/size_mo).round(2)} Mo"
      elsif self.file_file_size < size_terra
        "#{(self.file_file_size/size_go).round(2)} Go"
      end
    else
      "-"
    end
  end
end
