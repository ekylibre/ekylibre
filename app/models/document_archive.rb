# = Informations
#
# == License
#
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
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
# == Table: document_archives
#
#  archived_at       :datetime         not null
#  created_at        :datetime         not null
#  creator_id        :integer
#  document_id       :integer          not null
#  file_content_text :text
#  file_content_type :string(255)
#  file_file_name    :string(255)
#  file_file_size    :integer
#  file_fingerprint  :string(255)
#  file_pages_count  :integer
#  file_updated_at   :datetime
#  id                :integer          not null, primary key
#  lock_version      :integer          default(0), not null
#  template_id       :integer
#  updated_at        :datetime         not null
#  updater_id        :integer
#
class DocumentArchive < Ekylibre::Record::Base
  belongs_to :document, counter_cache: :archives_count, inverse_of: :archives
  belongs_to :template, class_name: "DocumentTemplate"
  has_attached_file :file, {
    path: ':tenant/:class/:id_partition/:style.:extension',
    styles: {
      default:   {format: :pdf, processors: [:reader, :counter, :freezer], clean: true},
      thumbnail: {format: :jpg, processors: [:sketcher]}
    }
  }
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :archived_at, :file_updated_at, allow_nil: true, on_or_after: Date.civil(1,1,1)
  validates_numericality_of :file_file_size, allow_nil: true, only_integer: true
  validates_length_of :file_content_type, :file_file_name, :file_fingerprint, allow_nil: true, maximum: 255
  validates_presence_of :archived_at, :document
  #]VALIDATORS]
  validates_presence_of :archived_at
  validates_attachment_presence :file
  validates_attachment_content_type :file, content_type: /(application|image)/

  before_validation(on: :create) do
    self.archived_at ||= Time.now
  end

  delegate :name, to: :template, prefix: true

  # Returns data of file
  def data
    path = self.file.path
    file_data = nil
    if path.exist?
      File.open(path, "rb") do |file|
        file_data = file.read
      end
    else
      raise StandardError.new("Archive (#{path}) does not exists!")
    end
    return file_data
  end

end
