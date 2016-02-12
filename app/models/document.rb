# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
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
#  created_at        :datetime         not null
#  creator_id        :integer
#  custom_fields     :jsonb
#  file_content_text :text
#  file_content_type :string
#  file_file_name    :string
#  file_file_size    :integer
#  file_fingerprint  :string
#  file_pages_count  :integer
#  file_updated_at   :datetime
#  id                :integer          not null, primary key
#  key               :string           not null
#  lock_version      :integer          default(0), not null
#  name              :string           not null
#  nature            :string
#  number            :string           not null
#  template_id       :integer
#  updated_at        :datetime         not null
#  updater_id        :integer
#  uploaded          :boolean          default(FALSE), not null
#

class Document < Ekylibre::Record::Base
  include Customizable
  belongs_to :template, class_name: 'DocumentTemplate'
  has_many :attachments, dependent: :destroy
  has_attached_file :file, path: ':tenant/:class/:id_partition/:style.:extension',
                           styles: {
                             default:   { format: :pdf, processors: [:reader, :counter, :freezer], clean: true },
                             thumbnail: { format: :jpg, processors: [:sketcher, :thumbnail], geometry: '320x320>' }
                           }
  refers_to :nature, class_name: 'DocumentNature'
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :file_updated_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_numericality_of :file_file_size, allow_nil: true, only_integer: true
  validates_inclusion_of :uploaded, in: [true, false]
  validates_presence_of :key, :name, :number
  # ]VALIDATORS]
  validates_length_of :number, allow_nil: true, maximum: 60
  validates_length_of :nature, allow_nil: true, maximum: 120
  # validates_inclusion_of :nature, in: nature.values
  # validates_attachment_presence :file
  validates_attachment_content_type :file, content_type: /(application|image|text)/

  delegate :name, to: :template, prefix: true
  acts_as_numbered

  # Returns the matching unique document for the given nature and key
  def self.of(nature, key)
    where(nature: nature.to_s, key: key.to_s)
  end

  before_validation do
    self.name ||= file.original_filename
    self.key ||= "#{Time.now.to_i}-#{file.original_filename}"
  end
end
