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
#  archives_count        :integer          default(0), not null
#  created_at            :datetime         not null
#  creator_id            :integer
#  datasource            :string(63)
#  datasource_parameters :text
#  id                    :integer          not null, primary key
#  lock_version          :integer          default(0), not null
#  name                  :string(255)      not null
#  nature                :string(63)       not null
#  number                :string(63)       not null
#  template_id           :integer
#  template_type         :string(255)
#  updated_at            :datetime         not null
#  updater_id            :integer
#

class Document < Ekylibre::Record::Base
  # belongs_to :origin, :polymorphic => true
  belongs_to :template, :class_name => "DocumentTemplate"
  has_many :archives, :class_name => "DocumentArchive"
  enumerize :nature, :in => Nomenclatures["document_natures"].items.keys.map(&:underscore), :predicates => {:prefix => true}
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :datasource, :nature, :number, :allow_nil => true, :maximum => 63
  validates_length_of :name, :template_type, :allow_nil => true, :maximum => 255
  validates_presence_of :name, :nature, :number
  #]VALIDATORS]

  acts_as_numbered


  before_validation(:on => :create) do
    if self.name.blank? and self.template
      if self.origin.nil?
        self.name = tc('name_without_origin', :template => self.template)
      else
        self.name = tc('name_with_origin', :template => self.template, :origin => self.origin.name)
      end
    end
  end


  def archive(data, options = {})

    self.archives.create!(:file => f)


    document = self.documents.build
    document.owner = owner
    document.extension = attributes[:format] || "pdf"
    method_name = [:document_name, :number, :code, :name, :id].detect{|x| owner.respond_to?(x)}
    document.printed_at = Time.now
    document.subdir = Date.today.strftime('%Y-%m')
    document.original_name = owner.send(method_name).to_s.simpleize+'.'+document.extension.to_s
    document.filename = owner.send(method_name).to_s.codeize+'-'+document.printed_at.to_i.to_s(36).upper+'-'+Document.generate_key+'.'+document.extension.to_s
    document.filesize = data.length
    document.sha256 = Digest::SHA256.hexdigest(data)
    document.crypt_mode = 'none'
    if document.save
      FileUtils.mkdir_p(document.path)
      File.open(document.file_path, 'wb') {|f| f.write(data) }
    else
      raise Exception.new(document.errors.inspect)
    end


  end


  def self.private_directory
    Ekylibre.private_directory.join('document-archives')
  end


end
