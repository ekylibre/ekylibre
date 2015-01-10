# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2015 Brice Texier, Thibaud Merigon
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
#  company_id    :integer          not null
#  created_at    :datetime         not null
#  creator_id    :integer          
#  crypt_key     :binary           
#  crypt_mode    :string(255)      not null
#  extension     :string(255)      
#  filename      :string(255)      
#  filesize      :integer          
#  id            :integer          not null, primary key
#  lock_version  :integer          default(0), not null
#  nature_code   :string(255)      
#  original_name :string(255)      not null
#  owner_id      :integer          
#  owner_type    :string(255)      
#  printed_at    :datetime         
#  sha256        :string(255)      not null
#  subdir        :string(255)      
#  template_id   :integer          
#  updated_at    :datetime         not null
#  updater_id    :integer          
#

class Document < CompanyRecord
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :filesize, :allow_nil => true, :only_integer => true
  validates_length_of :crypt_mode, :extension, :filename, :nature_code, :original_name, :owner_type, :sha256, :subdir, :allow_nil => true, :maximum => 255
  #]VALIDATORS]
  belongs_to :company
  belongs_to :owner, :polymorphic=>true
  belongs_to :template, :class_name=>"DocumentTemplate"

  attr_accessor :archive

  validates_presence_of :template_id, :subdir, :extension, :owner_type, :owner_id

  attr_readonly :company_id

  before_validation do
    self.nature_code = self.template.code if self.template
  end

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
    # File.join(self.company.private_directory, code, self.subdir)
    File.join(self.company.private_directory, "documents", code, self.subdir)
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

end
