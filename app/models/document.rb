# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: documents
#
#  archived_at       :datetime
#  created_at        :datetime         not null
#  creator_id        :integer
#  file_content_type :string(255)
#  file_file_name    :string(255)
#  file_file_size    :integer
#  file_fingerprint  :string(255)
#  file_updated_at   :datetime
#  id                :integer          not null, primary key
#  lock_version      :integer          default(0), not null
#  name              :string(255)      not null
#  nature            :string(63)       not null
#  origin_id         :integer
#  origin_type       :string(255)
#  template_id       :integer
#  updated_at        :datetime         not null
#  updater_id        :integer
#

class Document < Ekylibre::Record::Base
  belongs_to :origin, :polymorphic => true
  belongs_to :template, :class_name => "DocumentTemplate"
  has_attached_file :file
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :file_file_size, :allow_nil => true, :only_integer => true
  validates_length_of :nature, :allow_nil => true, :maximum => 63
  validates_length_of :file_content_type, :file_file_name, :file_fingerprint, :name, :origin_type, :allow_nil => true, :maximum => 255
  validates_presence_of :name, :nature
  #]VALIDATORS]

  def data
    path = self.file_path
    file_data = nil
    if File.exists? path
      File.open(path, "rb") do |file|
        file_data = file.read
      end
    else
      raise Exception.new("Archive (#{path}) does not exists!")
    end
    file_data
  end

  def path(strict=true)
    code = self.nature_code
    code.gsub!(/\*/, '') unless strict
    File.join(self.class.private_directory, "documents", code, self.subdir)
  end

  def file_path(strict=true)
    File.join(self.path(strict), self.filename)
  end


  def self.missing_files(update=false)
    count = 0
    for document in Document.all
      unless File.exists?(document.file_path(false))
        if update
          document.nature_code += '*'
          document.save(false)
        end
        count += 1
      end
    end
    return count
  end

  def self.generate_key(password_length=8)
    letters = %w(A B C D E F G H I J K L M N O P Q R S T U V W Y X Z)
    letters_length = letters.length
    password = ''
    password_length.times{password+=letters[(letters_length*rand).to_i]}
    password
  end

  def self.private_directory
    Ekylibre.private_directory
  end

end
