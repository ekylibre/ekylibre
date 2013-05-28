# -*- coding: utf-8 -*-
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
# == Table: document_templates
#
#  active       :boolean          not null
#  archiving    :string(63)       not null
#  by_default   :boolean          not null
#  created_at   :datetime         not null
#  creator_id   :integer
#  formats      :string(255)
#  id           :integer          not null, primary key
#  language     :string(3)        not null
#  lock_version :integer          default(0), not null
#  managed      :boolean          not null
#  name         :string(255)      not null
#  nature       :string(63)       not null
#  updated_at   :datetime         not null
#  updater_id   :integer
#

# Sources are stored in private/document_templates/:id/content.xml
class DocumentTemplate < Ekylibre::Record::Base
  cattr_reader :datasources
  attr_accessible :active, :archiving, :by_default, :language, :name, :nature, :managed, :source, :formats
  enumerize :archiving, :in => [:none, :first, :last, :all], :default => :none, :predicates => {:prefix => true}
  enumerize :nature, :in => Nomenclatures["document-natures"].items.values.select{|i| i.attributes["datasource"]}.map(&:name).map(&:underscore), :predicates => {:prefix => true}
  has_many :documents, :foreign_key => :template_id
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :language, :allow_nil => true, :maximum => 3
  validates_length_of :archiving, :nature, :allow_nil => true, :maximum => 63
  validates_length_of :formats, :name, :allow_nil => true, :maximum => 255
  validates_inclusion_of :active, :by_default, :managed, :in => [true, false]
  validates_presence_of :archiving, :language, :name, :nature
  #]VALIDATORS]
  validates_inclusion_of :nature, :in => self.nature.values

  after_save :set_by_default

  default_scope order(:name)
  scope :of_nature, lambda { |nature|
    raise ArgumentError.new("Unknown nature for a DocumentTemplate (got #{nature.inspect}:#{nature.class})") unless self.nature.values.include?(nature.to_s)
    where(:nature => nature.to_s, :active => true).order(:name)
  }
  scope :with_datasource, lambda { |datasource|
    raise ArgumentError.new("Unknown datasource (got #{datasource.inspect}:#{datasource.class}, #{self.datasources.keys.join(', ')} expected)") unless self.datasources.keys.include?(datasource.to_s)
    where(:nature => self.datasources[datasource.to_s], :active => true).order(:name)
  }


  protect(:on => :destroy) do
    self.documents.count <= 0
  end

  before_validation do
    # Check that given formats are all known
    unless self.formats.empty?
      self.formats = self.formats.to_s.downcase.strip.split(/[\s\,]+/).delete_if do |f|
        !Ekylibre::Reporting.formats.include?(f)
      end.join(", ")
    end
  end

  after_save do
    # Install file after save only
    if @source
      FileUtils.mkdir_p(self.source_path.dirname)
      File.open(self.source_path, "wb") do |f|
        f.write(@source.read)
      end
    end
  end

  # Always after protect on destroy
  after_destroy do
    if File.exist?(self.source_dir)
      FileUtils.rm_rf(self.source_dir)
    end
  end

  # Set the template's nature default
  def set_by_default
    if self.by_default or self.class.where(:by_default => true, :nature => self.nature).count != 1
      self.class.update_all({:by_default => false}, ["id != ? and nature = ?", self.id, self.nature])
      self.class.update_all({:by_default => true}, {:id => self.id})
    end
  end

  # Install the source of a document template
  # with all its dependencies
  def source=(file)
    @source = file
  end

  # Returns the expected dir for the source file
  def source_dir
    return self.class.sources_root.join(self.id.to_s)
  end

  # Returns the expected path for the source file
  def source_path
    return self.source_dir.join("content.xml")
  end

  # Print a document with the given datasource
  # Store if needed by template
  def print(*args)
    options = (args[-1].is_a?(Hash) ? args.delete_at(-1) : {})
    object = args.shift
    format = args.shift || :pdf

    # Load the report
    report = Beardley::Report.new(self.source_path)

    # Create datasource
    datasource = object.to_xml(options)

    # Call it with datasource
    data = report.send("to_#{format}", datasource)

    # Archive if needed
    self.archive(object, data, :format => format) if self.to_archive?

    # Returns the data with the filename
    return data
  end

  # Returns the list of formats of the templates
  def formats
    (self["formats"].blank? ? Ekylibre::Reporting.formats : self["formats"].strip.split(/[\s\,]+/))
  end


  # Archive the document
  # TODO: Review document archivage by template
  def archive(owner, data, attributes={})
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
    return document
  end

  # Returns the root directory for the document templates's sources
  def self.sources_root
    Ekylibre.private_directory.join("reporting")
  end

  # Loads in DB all default document templates
  def self.load_defaults(options = {})
    locale = (options[:locale] || Entity.of_company.language || I18n.locale).to_s
    Ekylibre::Record::Base.transaction do
      manageds = self.where(:managed => true).pluck(:id)
      for nature in self.nature.values
        source = Rails.root.join("config", "locales", locale, "prints", "#{nature}.xml")
        if source.exist?
          File.open(source, "rb:UTF-8") do |f|
            unless template = self.where(:nature => nature, :managed => true).first
              template = self.new({:nature => nature, :managed => true, :active => true, :by_default => false, :archiving => "last"}, :without_protection => true)
            end
            manageds.delete(template.id)
            template.attributes = {:source => f, :language => locale}
            template.name ||= template.nature.text
            template.save!
          end
        else
          puts "Cannot load a default document template #{nature}: No file found at #{source}"
          logger.info "Cannot load a default document template #{nature}: No file found at #{source}"
        end
      end
      self.destroy(manageds)
    end
    return true
  end

  # Load reverse hash from datasource to document nature
  def self.load_datasources
    @@datasources = HashWithIndifferentAccess.new
    for item in Nomenclatures["document-natures"].items.values
      if ds = item.attributes["datasource"]
        ds = ds.to_s.underscore.to_sym
        @@datasources[ds] ||= []
        @@datasources[ds] << item.name.underscore
      end
    end
  end

  # Load datasources now!
  load_datasources


end
