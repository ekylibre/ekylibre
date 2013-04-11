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
#  by_default   :boolean          default(TRUE), not null
#  country      :string(2)
#  created_at   :datetime         not null
#  creator_id   :integer
#  id           :integer          not null, primary key
#  language     :string(3)        default("???"), not null
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  nature       :string(63)       not null
#  source       :text
#  updated_at   :datetime         not null
#  updater_id   :integer
#


class DocumentTemplate < Ekylibre::Record::Base
  attr_accessible :active, :by_default, :code, :country, :family, :filename, :language, :name, :nature, :source, :archiving
  enumerize :archiving, :in => [:none, :first, :last, :all], :default => :none, :predicates => {:prefix => true}
  enumerize :nature, :in => Nomenclature::DocumentClassification.document_natures.map(&:name), :predicates => {:prefix => true}
  has_many :documents, :foreign_key => :template_id
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :country, :allow_nil => true, :maximum => 2
  validates_length_of :language, :allow_nil => true, :maximum => 3
  validates_length_of :archiving, :nature, :allow_nil => true, :maximum => 63
  validates_length_of :name, :allow_nil => true, :maximum => 255
  validates_inclusion_of :active, :by_default, :in => [true, false]
  validates_presence_of :archiving, :language, :name, :nature
  #]VALIDATORS]
  validates_inclusion_of :nature, :in => self.nature.values

  after_save :set_by_default

  default_scope order(:name)
  scope :of_nature, lambda { |nature|
    raise ArgumentError.new("Unknown nature for a DocumentTemplate (got #{nature.inspect}:#{nature.class})") unless self.nature.values.include?(nature.to_s)
    where(:nature => nature.to_s, :active => true).order(:name)
  }


  before_validation do
    self.filename ||= 'document'
    self.cache = Templating.compile(self.source, :xil) # rescue nil
    self.by_default = true if self.class.find_all_by_nature_and_by_default(self.nature, true).size <= 0
    return true
  end

  validate do
    errors.add(:source, :invalid) if self.cache.blank?
    if self.nature != "other"
      syntax_errors = self.filename_errors
      errors.add(:filename, :invalid_syntax, :errors => syntax_errors.to_sentence) unless syntax_errors.empty?
    end
  end

  before_save(:on => :create) do
    self.write_source!
    return true
  end

  before_save(:on => :update) do
    old = self.old_record
    if old.source_dir != self.source_dir
      FileUtils.mv(old.source_dir, self.source_dir)
    end
    if old.source != self.source
      self.write_source!
    end
  end

  protect(:on => :destroy) do
    self.documents.count <= 0
  end

  # Always after protect on destroy
  before_destroy do
    if File.exist?(self.source_path)
      FileUtils.rm_rf(self.source_path.dirname)
    end
  end

  # Set the template's nature default
  def set_by_default
    if self.by_default or self.class.where(:by_default => true, :nature => self.nature).count != 1
      self.class.update_all({:by_default => false}, ["id != ? and nature = ?", self.id, self.nature])
      self.class.update_all({:by_default => true}, {:id => self.id})
    end
  end

  # Returns the expected dir for the source file
  def source_dir
    return Rails.root.join("private", "reporting", self.code.to_s)
  end

  # Returns the expected path for the source file
  def source_path
    return self.source_dir.join("source.jrxml")
  end

  # Returns the path to the source file
  # Create the file if not exists
  def source_path!
    path = self.source_path
    self.write_source! unless path.exist?
    return path
  end

  # Write the source in its place
  def write_source!
    path = self.source_path
    FileUtils.mkdir_p(path.dirname)
    File.open(path, "wb") do |f|
      f.write(self.source)
    end
  end

  # Print a document with the given datasource
  # Store if needed by template
  def print(*args)
    options = (args[-1].is_a?(Hash) ? args.delete_at(-1) : {})
    object = args.shift
    format = args.shift || :pdf

    # Load the report
    report = Beardley::Report.new(self.source_path!)

    # Create datasource
    datasource = object.to_xml(options)

    # Call it with datasource
    data = report.send("to_#{format}", datasource)

    # Archive if needed
    self.archive(object, data, :format => format) if self.to_archive?

    # Returns the data with the filename
    return data
  end


  # # Print document without checks fast but dangerous if parameters are not checked before...
  # # Use carefully
  # def print_fastly!(*args)
  #   # Refresh cache if needed
  #   self.save! unless self.cache.starts_with?(Templating.preamble)

  #   # Try to find an existing archive
  #   owner = args[0].class.ancestors.include?(ActiveRecord::Base) ? args[0] : Company.first
  #   if self.to_archive and owner.is_a?(ActiveRecord::Base)
  #     document = Document.where(:nature_code => self.code, :owner_id => owner.id, :owner_type => owner.class.name).order("created_at DESC").first
  #     return document.data, document.original_name if document
  #   end

  #   # Build the PDF data
  #   if Rails.env.test?
  #     File.open(Rails.root.join("tmp", "document-template-#{self.id}.rb"), "wb") do |f|
  #       # self.cache.split("\n").each_with_index{|l,x| puts((x+1).to_s.rjust(4)+": "+l)}
  #       f.write self.cache.gsub(';', "\n")
  #     end
  #   end
  #   pdf = eval(self.cache)

  #   # Archive the document if necessary
  #   document = self.archive(owner, pdf, :extension => 'pdf') if self.to_archive

  #   return pdf, self.compute_filename(owner) + ".pdf"
  # end




  # # Print document raising Exceptions if necessary
  # def print!(*args)
  #   # Refresh cache if needed
  #   self.save! unless self.cache.starts_with?(Templating.preamble)

  #   # Analyze and cleans parameters
  #   parameters = self.class.document_natures[self.nature.to_sym]
  #   raise StandardError.new(tc(:unvalid_nature)) if parameters.nil?
  #   if args[0].is_a? Hash
  #     hash = args[0]
  #     parameters.each_index do |i|
  #       args[i] = hash[parameters[i][0]]||hash["p"+i.to_s]
  #     end
  #   end
  #   raise ArgumentError.new("Bad number of arguments, #{args.size} for #{parameters.size}") if args.size != parameters.size

  #   parameters.each_index do |i|
  #     args[i] = parameters[i][1].find_by_id(args[i].to_s.to_i) if parameters[i][1].ancestors.include?(ActiveRecord::Base) and not args[i].is_a? parameters[i][1]
  #     args[i] = args[i].to_date if args[i].class == String and parameters[i][1] == Date
  #     raise ArgumentError.new("#{parameters[i][1].name} expected, got #{args[i].inspect}") unless args[i].class == parameters[i][1]
  #   end

  #   # Try to find an existing archive
  #   if self.to_archive and args[0].class.ancestors.include?(ActiveRecord::Base)
  #     document = Document.where(:nature_code => self.code, :owner_id => owner.id, :owner_type => owner.class.name).order("created_at DESC").first
  #     return document.data, document.original_name if document
  #   end

  #   # Build the PDF data
  #   begin
  #     pdf = eval(self.cache)
  #   rescue Exception => e
  #     puts e.message+"\nCache:\n"+self.cache
  #     raise e
  #   end

  #   # Archive the document if necessary
  #   document = self.archive(owner, pdf, :extension => 'pdf') if self.to_archive

  #   return pdf, self.compute_filename(owner)+".pdf"
  # end


  # # Print document or exception if necessary
  # def print(*args)
  #   begin
  #     return self.print!(*args)
  #   rescue Exception => e
  #     return self.class.error_document(e)
  #   end
  # end

  # # Print! a document
  # def self.print(nature, options = {})
  #   template ||= options[:template]
  #   template = if template.is_a? String or template.is_a? Symbol
  #                self.find_by_active_and_nature_and_code(true, nature.to_s, template.to_s)
  #              else
  #                self.find_by_active_and_nature_and_by_default(true, nature.to_s, true)
  #              end
  #   raise ArgumentError.new("Unfound template") unless template
  #   parameters = []
  #   for p in self.document_natures[nature.to_sym]
  #     x = options[p[0]]
  #     raise ArgumentError.new("options[:#{p[0]}] must be a #{p[1].name} (got #{x.class.name})") if x.class != p[1]
  #     parameters << x
  #   end
  #   return template.print_fastly!(*parameters)
  # end

  # Archive the document
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

  # def sample
  #   self.save!
  #   code = Templating.compile(self.source, :xil, :mode => :debug)
  #   pdf = nil
  #   # code.split("\n").each_with_index{|l,x| puts((x+1).to_s.rjust(4)+": "+l)}
  #   begin
  #     pdf = eval(code)
  #   rescue Exception => e
  #     pdf = self.class.error_document(e)
  #   end
  #   pdf
  # end

  # Generate a copy of the template with a different code.
  def duplicate
    attrs = self.attributes.dup
    attrs.delete("id")
    attrs.delete("lock_version")
    attrs.delete_if{|k,v| k.match(/^(cre|upd)at((e|o)r_id|ed_(at|on))/) }
    while self.class.where(:code => attrs["code"]).first
      attrs["code"].succ!
    end
    return self.class.create(attrs, :without_protection => true)
  end


  # # Produces a generic document with the trace of the thrown exception
  # def self.error_document(exception)
  #   Templating::Writer.generate do |doc|
  #     doc.page(:size => "A4", :margin => 15.mm) do |p|
  #       if exception.is_a? Exception
  #         p.slice do |s|
  #           s.text("Exception: "+exception.inspect)
  #         end
  #         for item in exception.backtrace
  #           p.slice do |s|
  #             s.text(item)
  #           end
  #         end
  #       else
  #         p.slice do |s|
  #           s.text("Error: "+exception.inspect, :width => 180.mm)
  #         end
  #       end
  #     end
  #   end
  # end


  # Loads in DB all default document templates
  def self.load_defaults(options = {})
    locale = (options[:locale] || Entity.of_company.language || I18n.locale).to_s
    country = Entity.of_company.country || 'fr'
    files_dir = Rails.root.join("config", "locales", locale, "prints")
    all_templates = ::I18n.translate('models.document_template.default') || {}
    for family, templates in all_templates
      for template, attributes in templates
        next unless File.exist? files_dir.join("#{template}.xml")
        File.open(files_dir.join("#{template}.xml"), "rb:UTF-8") do |f|
          nature, code = (attributes[:nature] || template), template.to_s # attributes[:name].to_s.codeize[0..7]
          doc = self.find_by_code(code) || self.new(:code => code)
          doc.attributes = HashWithIndifferentAccess.new(:active => true, :language => locale, :country => country, :family => family, :by_default => false, :nature => nature, :filename => (attributes[:filename] || "File"))
          doc.name = (attributes[:name] || doc.nature.text).to_s
          doc.to_archive = true if attributes[:to_archive] == "true"
          doc.source = f.read.force_encoding('UTF-8')
          doc.save!
        end
      end
    end if all_templates.is_a?(Hash)
    return true
  end

end
