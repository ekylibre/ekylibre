# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2021 Ekylibre SAS
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
#  created_at         :datetime         not null
#  creator_id         :integer
#  custom_fields      :jsonb
#  file_content_text  :text
#  file_content_type  :string
#  file_file_name     :string
#  file_file_size     :integer
#  file_fingerprint   :string
#  file_pages_count   :integer
#  file_updated_at    :datetime
#  id                 :integer          not null, primary key
#  key                :string           not null
#  lock_version       :integer          default(0), not null
#  mandatory          :boolean          default(FALSE)
#  name               :string           not null
#  nature             :string
#  number             :string           not null
#  sha256_fingerprint :string
#  signature          :text
#  template_id        :integer
#  updated_at         :datetime         not null
#  updater_id         :integer
#  uploaded           :boolean          default(FALSE), not null
#

class Document < ApplicationRecord
  include Customizable
  belongs_to :template, class_name: 'DocumentTemplate'
  has_many :attachments, dependent: :destroy
  has_attached_file :file, path: ':tenant/:class/:id_partition/:style.:extension',
                           styles: {
                             default:   { format: :pdf, processors: %i[reader counter freezer], clean: true },
                             thumbnail: { format: :jpg, processors: %i[sketcher thumbnail], geometry: '320x320>' }
                           }
  refers_to :nature, class_name: 'DocumentNature'
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :file_content_text, :signature, length: { maximum: 500_000 }, allow_blank: true
  validates :file_content_type, :file_file_name, :file_fingerprint, :sha256_fingerprint, length: { maximum: 500 }, allow_blank: true
  validates :file_file_size, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :file_updated_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }, allow_blank: true
  validates :key, :name, :number, presence: true, length: { maximum: 500 }
  validates :mandatory, inclusion: { in: [true, false] }, allow_blank: true
  validates :processable_attachment, :uploaded, inclusion: { in: [true, false] }
  # ]VALIDATORS]
  validates :number, length: { allow_nil: true, maximum: 60 }
  validates :nature, length: { allow_nil: true, maximum: 120 }
  # validates_inclusion_of :nature, in: nature.values
  # validates_attachment_presence :file
  validates_attachment_content_type :file, content_type: /(application|image|text)/

  before_post_process :processable_attachment?

  delegate :name, to: :template, prefix: true
  acts_as_numbered

  protect(on: :destroy) do
    mandatory
  end

  # Returns the matching unique document for the given nature and key
  def self.of(nature, key)
    where(nature: nature.to_s, key: key.to_s)
  end

  before_validation do
    self.name ||= file.original_filename
    self.key ||= "#{Time.now.to_i}-#{file.original_filename}"
    # DB limitation
    self.file_content_text = file_content_text.truncate(500_000) if file_content_text
  end

  def attachement_presence
    if self.attachments
      true
    else
      false
    end
  end

  def ocr_presence
    self.klippa_metadata.present?
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
